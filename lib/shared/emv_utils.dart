class EmvUtils {
  static String formatField(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  static String crc16(String data) {
    int crc = 0xFFFF;
    const int poly = 0x1021;
    for (final byte in data.codeUnits) {
      crc ^= (byte & 0xFF) << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Simple TLV parse (non-strict) returning list of maps with keys: id, size, value, emvName
  static List<Map<String, dynamic>> parseEmv(String data, {String? parentTag}) {
    int i = 0;
    final result = <Map<String, dynamic>>[];
    while (i < data.length) {
      if (i + 4 > data.length) break; // safety
      final tag = data.substring(i, i + 2);
      final size = int.tryParse(data.substring(i + 2, i + 4)) ?? 0;
      final end = (i + 4 + size).clamp(0, data.length);
      final value = data.substring(i + 4, end);
      final tagKey = parentTag == null ? tag : '$tag-$parentTag';
      final emvName = EmvTags.map[tagKey] ?? EmvTags.map[tag] ?? '';
      result.add({'id': tag, 'size': size, 'value': value, 'emvName': emvName});

      if (tag == '26' || tag == '62') {
        result.addAll(parseEmv(value, parentTag: tag));
      }
      i = i + 4 + size;
    }
    return result;
  }

  /// Parse to map (first occurrence per tag kept). For editor use.
  static Map<String, String> parseToMap(String data) {
    int i = 0;
    final map = <String, String>{};
    while (i < data.length) {
      if (i + 4 > data.length) break;
      final tag = data.substring(i, i + 2);
      final size = int.tryParse(data.substring(i + 2, i + 4)) ?? 0;
      final end = (i + 4 + size).clamp(0, data.length);
      final value = data.substring(i + 4, end);
      map[tag] = value;
      i = i + 4 + size;
    }
    return map;
  }

  /// Build TLV string from a tag->value map in ascending tag order.
  static String buildFromMap(Map<String, String> fields) {
    final sortedKeys = fields.keys.toList()..sort();
    final sb = StringBuffer();
    for (final tag in sortedKeys) {
      final value = fields[tag] ?? '';
      sb.write(tag);
      sb.write(value.length.toString().padLeft(2, '0'));
      sb.write(value);
    }
    return sb.toString();
  }
}

class EmvTags {
  static const map = <String, String>{
    '00': 'Payload Format Indicator',
    '01': 'Point of Initiation Method',
    '26': 'Merchant Account Information - Pix',
    '00-26': 'GUI',
    '01-26': 'Pix Key',
    '02-26': 'Description',
    '52': 'Merchant Category Code',
    '53': 'Transaction Currency',
    '54': 'Transaction Amount',
    '58': 'Country Code',
    '59': 'Merchant Name',
    '60': 'Merchant City',
    '62': 'Additional Data Field Template',
    '05-62': 'Reference Label',
    '63': 'CRC',
  };
}

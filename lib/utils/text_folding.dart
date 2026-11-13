// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

const latinAccentedCharacters =
    'àáâãäåçèéêëìíîïðñòóôõöøùúûüýÿāăąćĉċčďđēĕėęěĝğġģĥħĩīĭįıĵķ'
    'ĺļľŀłńņňōŏőŕŗřśŝşšţťŧũūŭůűųŵŷźżžơưǎǐǒǔǖǘǚǜǟǡǧǩǫǭǰǵǹǻȁȃȅȇ'
    'ȉȋȍȏȑȓȕȗșțȟȧȩȫȭȯȱȳḁḃḅḇḉḋḍḏḑḓḕḗḙḛḝḟḡḣḥḧḩḫḭḯḱḳḵḷḹḻḽḿṁṃṅṇṉṋ'
    'ṍṏṑṓṕṗṙṛṝṟṡṣṥṧṩṫṭṯṱṳṵṷṹṻṽṿẁẃẅẇẉẋẍẏẑẓẕẖẗẘẙạảấầẩẫậắằẳẵặẹẻẽ'
    'ếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ';

const latinBaseCharacters =
    'aaaaaaceeeeiiiidnoooooouuuuyyaaaccccddeeeeegggghhiiiiijk'
    'lllllnnnooorrrsssstttuuuuuuwyzzzouaiouuuuuaagkoojgnaaaee'
    'iioorruusthaeooooyabbbcdddddeeeeefghhhhhiikkkllllmmmnnnn'
    'oooopprrrrsssssttttuuuuuvvwwwwwxxyzzzhtwyaaaaaaaaaaaaeee'
    'eeeeeiioooooooooooouuuuuuuyyyy';

final Uint16List _foldTable = _buildFoldTable();

const int _firstAccentedUnit = 0xe0;

Uint16List _buildFoldTable() {
  final table = Uint16List(0x1f00);
  for (var index = 0; index < latinAccentedCharacters.length; index++) {
    table[latinAccentedCharacters.codeUnitAt(index)] =
        latinBaseCharacters.codeUnitAt(index);
  }
  return table;
}

String foldText(String text) {
  final lowered = text.toLowerCase();
  Uint16List? folded;
  for (var index = 0; index < lowered.length; index++) {
    final unit = lowered.codeUnitAt(index);
    if (unit < _firstAccentedUnit || unit >= _foldTable.length) continue;
    final base = _foldTable[unit];
    if (base == 0) continue;
    folded ??= Uint16List.fromList(lowered.codeUnits);
    folded[index] = base;
  }
  return folded == null ? lowered : String.fromCharCodes(folded);
}

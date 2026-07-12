enum TagIconType {
  character,
  materialIcon;

  int toInt() => index;

  static TagIconType fromInt(int? value) =>
      value == null ? TagIconType.character : TagIconType.values[value];
}

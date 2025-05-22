namespace EyeNeko {
    namespace Enum {
        public int value (string enum, string name) {
            return ((EnumClass) Type.from_name (enum).class_peek ()).get_value_by_name ((string) name).value;
        }

        public string alias (string enum, int value) {
            return ((EnumClass) Type.from_name (enum).class_peek ()).get_value (value).value_name;
        }
    }
}

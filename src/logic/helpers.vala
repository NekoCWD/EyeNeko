namespace EyeNeko {
    namespace Enum {
        public int value (string enum, string name) {
            return ((EnumClass) Type.from_name (enum).class_peek ()).get_value_by_name ((string) name).value;
        }

        public string alias (string enum, int value) {
            return ((EnumClass) Type.from_name (enum).class_peek ()).get_value (value).value_name;
        }
    }
    namespace Env {
        string get_variable_or (string name, string default) {
            var str = Environment.get_variable (name);
            return (str == null ? default : str);
        }
    }
}

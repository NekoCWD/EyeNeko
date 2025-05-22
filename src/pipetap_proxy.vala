[DBus (name = "io.gitlab.nekocwd.pipetap1")]
public interface PipeTap : Object {
    public abstract int focus { get; set; }

    private static PipeTap _instance = null;
    public static PipeTap instance {
        get {
            if (_instance == null)
                _instance = Bus.get_proxy_sync<PipeTap> (BusType.SESSION, "io.gitlab.nekocwd.pipetap", "/io/gitlab/nekocwd/pipetap", DBusProxyFlags.NONE);
            return _instance;
        }
    }
}

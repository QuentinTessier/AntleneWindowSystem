# AntleneWindowSystem
Antlene Window lib

```Zig

const AntleneWindowSystem = @import("AntleneWindowSystem");

const MyEventHandler = struct {

    pub fn dispatch(self: *MyEventHandler, some_event: anytype) void {
        ...
    }

    pub fn onCloseEvent(self: *MyEventHandler, _: *Window) void {
        self.dispatch(.close);
    }

    pub fn onKeyEvent(self: *MyEventHandle, _: *Window, e: AntleneWindowSystem.KeyEvent) void {
        self.dispatch(e);
    }

};

const Window = AntleneWindowSystem.PlatformWindow(MyEventHandler);

pub fn onClose(_: *MyEventHandler, run: *bool) void {
    run.* = false;
}

pub fn main() anyerror!void {
    var eventHandler = MyEventHandler.init();
    var window = Window.init("Example", 1920, 1080, &eventHandler);

    var run: bool = true;
    eventHandler.listen(.close, &run, &onClose);

    while (run) {
        window.pollEvent();
    
        // Do something here
    }
}

```
const std = @import("std");
const EventDataType = @import("EventDataType.zig");
pub const KeyCode = EventDataType.KeyCode;
pub const MouseButton = EventDataType.MouseButton;
pub const Size = EventDataType.Size;
pub const Position = EventDataType.Position;

pub const KeyEvent = union(enum(u8)) {
    pressed: KeyCode,
    released: KeyCode,
    repeated: struct { key: KeyCode, n: u32 },
};

pub const MouseButtonEvent = union(enum(u8)) {
    pressed: MouseButton,
    released: MouseButton,
};

pub const MouseScrollEvent = struct { amount: f32 };

pub const MouseMovedEvent = struct { x: i32, y: i32 };

pub const FocusEvent = struct { hasFocus: bool };

pub const MovedEvent = struct {
    old: Position,
    new: Position,
};

pub const ResizeEvent = struct {
    old: Size,
    new: Size,
};

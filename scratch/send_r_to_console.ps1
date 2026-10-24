Add-Type @"
using System;
using System.Runtime.InteropServices;

public class ConsoleInputSender {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool FreeConsole();

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool AttachConsole(uint dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteConsoleInput(
        IntPtr hConsoleInput,
        INPUT_RECORD[] lpBuffer,
        uint nLength,
        out uint lpNumberOfEventsWritten
    );

    [StructLayout(LayoutKind.Explicit)]
    public struct INPUT_RECORD {
        [FieldOffset(0)]
        public ushort EventType;
        [FieldOffset(4)]
        public KEY_EVENT_RECORD KeyEvent;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEY_EVENT_RECORD {
        public bool bKeyDown;
        public ushort wRepeatCount;
        public ushort wVirtualKeyCode;
        public ushort wVirtualScanCode;
        public char UnicodeChar;
        public uint dwControlKeyState;
    }

    public static bool SendChar(uint pid, char c) {
        FreeConsole();
        if (!AttachConsole(pid)) {
            return false;
        }

        IntPtr handle = GetStdHandle(-10); // STD_INPUT_HANDLE
        if (handle == IntPtr.Zero || handle == new IntPtr(-1)) {
            FreeConsole();
            return false;
        }

        INPUT_RECORD[] records = new INPUT_RECORD[2];
        // Key down
        records[0].EventType = 1;
        records[0].KeyEvent.bKeyDown = true;
        records[0].KeyEvent.wRepeatCount = 1;
        records[0].KeyEvent.wVirtualKeyCode = (ushort)char.ToUpper(c);
        records[0].KeyEvent.UnicodeChar = c;

        // Key up
        records[1].EventType = 1;
        records[1].KeyEvent.bKeyDown = false;
        records[1].KeyEvent.wRepeatCount = 1;
        records[1].KeyEvent.wVirtualKeyCode = (ushort)char.ToUpper(c);
        records[1].KeyEvent.UnicodeChar = c;

        uint written;
        bool ok = WriteConsoleInput(handle, records, 2, out written);
        FreeConsole();
        return ok && written == 2;
    }
}
"@

$pidToSend = 24368
$res = [ConsoleInputSender]::SendChar($pidToSend, [char]'r')
Write-Output "Send to 24368: $res"
if (-not $res) {
    $res2 = [ConsoleInputSender]::SendChar(7876, [char]'r')
    Write-Output "Send to 7876: $res2"
}

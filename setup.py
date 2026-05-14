"""py2app build configuration for TomoTexture.

Build:
    python3.14 setup.py py2app --arch=arm64

Why arm64-only and not universal2: numpy 2.x and recent Pillow stopped
publishing universal2 wheels, so a universal2 .app would have a hollow x86_64
slice that crashes on import. Apple Silicon-only is honest; users on Intel
Mac are vanishingly rare for this app's audience (Ryujinx + Switch
emulation is barely viable on Intel anyway).
"""
from setuptools import setup

APP = ["app_main.py"]

OPTIONS = {
    "argv_emulation": False,
    "plist": {
        "CFBundleName": "TomoTexture",
        "CFBundleDisplayName": "TomoTexture",
        "CFBundleIdentifier": "com.zachmtz.tomotexture",
        "CFBundleShortVersionString": "1.0.0",
        "CFBundleVersion": "1.0.0",
        "NSHighResolutionCapable": True,
        "LSMinimumSystemVersion": "11.0",
        "NSHumanReadableCopyright": (
            "TomoTexture by Alfonso Mallozzi. macOS launcher MIT-licensed by Zach Martz."
        ),
    },
    "packages": [
        "numpy",
        "PIL",
        "yaml",
        "zstandard",
    ],
    # pyinstxtractor_ng is a top-level module (not a package) — listed in
    # `includes`, not `packages`, so py2app pulls in its single .py file.
    "includes": [
        "tkinter",
        # Upstream uses these tkinter submodules; py2app doesn't auto-include
        # them just because we import the top-level tkinter package.
        "tkinter.filedialog",
        "tkinter.messagebox",
        "tkinter.ttk",
        "tkinter.simpledialog",
        "tkinter.colorchooser",
        "tkinter.font",
        "tkinter.scrolledtext",
        "ntpath",
        "runpy",
        "urllib.request",
        "pyinstxtractor_ng",
        "certifi",
    ],
}

setup(
    name="TomoTexture",
    app=APP,
    options={"py2app": OPTIONS},
    setup_requires=["py2app"],
)

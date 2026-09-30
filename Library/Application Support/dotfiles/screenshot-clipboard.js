// Run with osascript -l JavaScript. Existing screenshots are left alone at startup.
ObjC.import('Cocoa');

const folder = ObjC.unwrap($.NSHomeDirectory()) + '/Desktop/Screenshots';
const manager = $.NSFileManager.defaultManager;
const clipboard = $.NSPasteboard.generalPasteboard;

function scanImages() {
    const error = Ref();
    const names = manager.contentsOfDirectoryAtPathError($(folder), error);
    if (names.isNil()) {
        throw Error('Cannot read screenshot folder: ' + ObjC.unwrap(error[0].localizedDescription));
    }
    const result = new Map();
    for (const name of ObjC.deepUnwrap(names)) {
        if (!name.toLowerCase().endsWith('.png')) continue;
        const path = folder + '/' + name;
        const attributes = manager.attributesOfItemAtPathError($(path), null);
        if (!attributes.isNil()) {
            result.set(path, {
                size: Number(ObjC.unwrap(attributes.objectForKey($.NSFileSize))),
                modified: Number(attributes.objectForKey($.NSFileModificationDate).timeIntervalSince1970)
            });
        }
    }
    return result;
}

function copyImage(path) {
    const image = $.NSImage.alloc.initWithContentsOfFile($(path));
    if (image.isNil()) return false;
    clipboard.clearContents;
    if (!clipboard.writeObjects($.NSArray.arrayWithObject(image))) {
        throw Error('Cannot copy screenshot to clipboard: ' + path);
    }
    return true;
}

let previous = scanImages();
const handled = new Set(previous.keys());
while (true) {
    $.NSThread.sleepForTimeInterval(1);
    const current = scanImages();
    const ready = [];
    for (const [path, info] of current) {
        const last = previous.get(path);
        // Wait until a new file has the same size and modification time on two scans.
        if (!handled.has(path) && last && info.size > 0 &&
            info.size === last.size && info.modified === last.modified) {
            ready.push([path, info]);
        }
    }
    // When several screenshots arrive together, leave the newest on the clipboard.
    ready.sort((a, b) => a[1].modified - b[1].modified);
    for (const [path] of ready) {
        if (copyImage(path)) handled.add(path);
    }
    for (const path of handled) {
        if (!current.has(path)) handled.delete(path);
    }
    previous = current;
}

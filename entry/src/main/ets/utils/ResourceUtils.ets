import { UIContext } from '@kit.ArkUI';
import GlobalContext from './GlobalContext';

export class ResourceUtils {
  // Helper to safely get the HostContext
  static getHostCtx(ui: Context) {
    const ctx = GlobalContext.getInstance().getAppContext();
    if (!ctx) {
      throw new Error('[ResourceUtils] Global context is undefined');
    }
    return ctx;
  }

  // Sync helper for simple string resources
  static getStringSync(ui: Context, res: Resource): string {
    return ResourceUtils.getHostCtx(ui).resourceManager.getStringSync(res.id);
  }

  // Async helper for string resources
  static async getString(ui: Context, res: Resource): Promise<string> {
    return ResourceUtils.getHostCtx(ui).resourceManager.getStringValue(res.id);
  }

  // Reads the raw file and triggers the manual decode
  static async readRawfileText(ui: Context, filename: string): Promise<string> {
    const host = ResourceUtils.getHostCtx(ui);
    const bytes = await host.resourceManager.getRawFileContent(filename);
    return ResourceUtils.utf8Decode(bytes);
  }

  // Wrapper to parse JSON directly
  static async readRawfileJson<T>(ui: Context, filename: string): Promise<T> {
    const text = await ResourceUtils.readRawfileText(ui, filename);
    return JSON.parse(text) as T;
  }

  // Manual UTF-8 Decoder
  // Handles variable-length characters (1-4 bytes) and BOM logic
  private static utf8Decode(bytes: Uint8Array): string {
    let out = '';
    let i = 0;
    const len = bytes.length;

    // Skip BOM if present
    if (len >= 3 && bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF) {
      i = 3;
    }

    while (i < len) {
      const b1 = bytes[i++];

      // ASCII (1 byte)
      if (b1 < 0x80) {
        out += String.fromCharCode(b1);
        continue;
      }

      // 2-byte sequence
      if ((b1 & 0xE0) === 0xC0) {
        if (i >= len) {
          break;
        }
        const b2 = bytes[i++];
        if ((b2 & 0xC0) !== 0x80) {
          continue;
        }
        const cp = ((b1 & 0x1F) << 6) | (b2 & 0x3F);
        out += String.fromCharCode(cp);
        continue;
      }

      // 3-byte sequence
      if ((b1 & 0xF0) === 0xE0) {
        if (i + 1 >= len) {
          break;
        }
        const b2 = bytes[i++];
        const b3 = bytes[i++];
        if ((b2 & 0xC0) !== 0x80 || (b3 & 0xC0) !== 0x80) {
          continue;
        }
        const cp = ((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
        out += String.fromCharCode(cp);
        continue;
      }

      // 4-byte sequence (e.g. Emojis)
      if ((b1 & 0xF8) === 0xF0) {
        if (i + 2 >= len) {
          break;
        }
        const b2 = bytes[i++]
        const b3 = bytes[i++]
        const b4 = bytes[i++];
        if ((b2 & 0xC0) !== 0x80 || (b3 & 0xC0) !== 0x80 || (b4 & 0xC0) !== 0x80) {
          continue;
        }
        const cp = ((b1 & 0x07) << 18) | ((b2 & 0x3F) << 12) | ((b3 & 0x3F) << 6) | (b4 & 0x3F);

        // Surrogate pair calculation for 4-byte chars
        const offset = cp - 0x10000;
        out += String.fromCharCode(0xD800 + (offset >> 10), 0xDC00 + (offset & 0x3FF));
        continue;
      }

      out += '\uFFFD'; // Replacement char for errors
    }
    return out;
  }
}

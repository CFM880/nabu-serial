# nabu-serial

English | **中文**

小米平板 5（`nabu`）的 **USB CDC-ACM 串口调试控制台**：用 configfs gadget 把内核
日志从 USB-C 口引到主机 PC，方便在「黑屏 / SSH 不通」时抓日志。

## 原理

- 内核只编了 configfs 的 CDC-ACM 功能（`CONFIG_USB_CONFIGFS_ACM`，见
  `config/nabu-serial.config`），**没有** legacy 的 `CONFIG_USB_G_SERIAL`，所以
  `/dev/ttyGS0` 要等 userspace 建好 gadget 才出现。
- `libexec/nabu-usb-console.sh`（由 `system/nabu-usb-console.service` 拉起）创建
  `acm.usb0` 并绑定到第一个 UDC；主机侧就会出现 `/dev/ttyACM*`。
- 使用方的内核 cmdline 带 `console=ttyGS0`（nabu-main 的
  `debian/config/debian.cmdline`），printk 才会走到串口。ttyGS 控制台带
  `CON_PRINTBUFFER`，gadget 一建好就会把整段开机 ring buffer 回放出来。
- `serial-getty@ttyGS0.service` 必须保持 **mask**：cmdline 有 `console=ttyGS0` 时
  systemd 会自动拉起对应的 getty，而 ttyGS0 只有在主机枚举 gadget 后才出现，
  它的 `dev-ttyGS0.device` 依赖会让无主机线缆时每次开机卡满 90s 设备超时。

## 内容

```text
config/nabu-serial.config
libexec/nabu-usb-console.sh
system/nabu-usb-console.service
```

## 抓取

在连着平板 USB-C 的 PC 上：

```sh
ls /dev/ttyACM*
nabu-main/debian/capture-serial.sh -t -o nabu-serial.log
```

细节见 `nabu-main/debian/config/USB-CONSOLE.md`（本构建把 USB-C 固定为 device 角色；
另外需要**屏蔽充电**——即用一个不含 `nabu-power` 的产品——让 USB-C 空出来给 gadget）。

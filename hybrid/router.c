/*
 * Hybrid Boot Router for Xiaomi POCO C40 (frost / JLQ JR510)
 * Author: Fakezay
 *
 * Routes PID 1 execution between MIUI Android 11 and TWRP v19 Recovery
 * based on kernel cmdline parameters passed by the bootloader.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>

static void klog(const char *msg) {
    int fd = open("/dev/kmsg", O_WRONLY);
    if (fd >= 0) {
        write(fd, msg, strlen(msg));
        close(fd);
    }
}

static void safe_symlink(const char *target, const char *linkpath) {
    unlink(linkpath);
    symlink(target, linkpath);
}

int main(int argc, char **argv) {
    // 1. Remount rootfs as read-write
    mount(NULL, "/", NULL, MS_REMOUNT, NULL);

    // 2. Mount proc and devtmpfs
    mkdir("/proc", 0755);
    mount("proc", "/proc", "proc", 0, NULL);

    mkdir("/dev", 0755);
    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);

    klog("<6>[HYBRID_ROUTER] Xiaomi POCO C40 Hybrid Boot Router v1.0 (Fakezay)\n");

    // 3. Read kernel cmdline
    char cmdline[4096] = {0};
    int fd = open("/proc/cmdline", O_RDONLY);
    if (fd >= 0) {
        ssize_t n = read(fd, cmdline, sizeof(cmdline) - 1);
        if (n > 0) cmdline[n] = '\0';
        close(fd);
    }

    // 4. Inspect boot parameters
    int force_normal = (strstr(cmdline, "androidboot.force_normal_boot=1") != NULL);
    int mode_recovery = (strstr(cmdline, "androidboot.mode=recovery") != NULL) ||
                        (strstr(cmdline, "boot-recovery") != NULL) ||
                        (strstr(cmdline, "androidboot.bootreason=reboot,recovery") != NULL) ||
                        (strstr(cmdline, "androidboot.bootreason=recovery") != NULL);

    int boot_android = force_normal && !mode_recovery;

    char *const new_argv[] = {"/init", NULL};
    char *const new_envp[] = {"PATH=/system/bin:/bin", NULL};

    if (boot_android) {
        klog("<6>[HYBRID_ROUTER] Boot mode: ANDROID MIUI 11 (force_normal_boot=1)\n");

        // Hide recovery binary so stock first-stage init runs FirstStageMount
        unlink("/system/bin/recovery");

        // Point /system/bin/init to stock init
        safe_symlink("/system/bin/init_stock", "/system/bin/init");

        // Stock fstab and prop.default
        safe_symlink("/system/etc/recovery.fstab_stock", "/system/etc/recovery.fstab");
        safe_symlink("/prop.default_stock", "/prop.default");

        // Stock contexts & sepolicy
        safe_symlink("/plat_file_contexts_stock", "/plat_file_contexts");
        safe_symlink("/plat_property_contexts_stock", "/plat_property_contexts");
        safe_symlink("/product_file_contexts_stock", "/product_file_contexts");
        safe_symlink("/product_property_contexts_stock", "/product_property_contexts");
        safe_symlink("/system_ext_file_contexts_stock", "/system_ext_file_contexts");
        safe_symlink("/system_ext_property_contexts_stock", "/system_ext_property_contexts");
        safe_symlink("/vendor_file_contexts_stock", "/vendor_file_contexts");
        safe_symlink("/vendor_property_contexts_stock", "/vendor_property_contexts");
        safe_symlink("/sepolicy_stock", "/sepolicy");

        // Unmount temporary filesystems before handing over to stock init
        umount("/dev");
        umount("/proc");

        execve("/system/bin/init_stock", new_argv, new_envp);
        execve("/system/bin/init", new_argv, new_envp);
    } else {
        klog("<6>[HYBRID_ROUTER] Boot mode: TWRP RECOVERY v19 (recovery trigger detected)\n");

        // Ensure TWRP recovery binary is active at /system/bin/recovery
        safe_symlink("/system/bin/recovery.twrp", "/system/bin/recovery");

        // Point /system/bin/init to TWRP init
        safe_symlink("/system/bin/init_twrp", "/system/bin/init");

        // TWRP fstab and prop.default
        safe_symlink("/system/etc/recovery.fstab_twrp", "/system/etc/recovery.fstab");
        safe_symlink("/prop.default_twrp", "/prop.default");

        // TWRP contexts & sepolicy
        safe_symlink("/plat_file_contexts_twrp", "/plat_file_contexts");
        safe_symlink("/plat_property_contexts_twrp", "/plat_property_contexts");
        safe_symlink("/product_file_contexts_twrp", "/product_file_contexts");
        safe_symlink("/product_property_contexts_twrp", "/product_property_contexts");
        safe_symlink("/system_ext_file_contexts_twrp", "/system_ext_file_contexts");
        safe_symlink("/system_ext_property_contexts_twrp", "/system_ext_property_contexts");
        safe_symlink("/vendor_file_contexts_twrp", "/vendor_file_contexts");
        safe_symlink("/vendor_property_contexts_twrp", "/vendor_property_contexts");
        safe_symlink("/sepolicy_twrp", "/sepolicy");

        // Unmount temporary filesystems
        umount("/dev");
        umount("/proc");

        execve("/system/bin/init_twrp", new_argv, new_envp);
        execve("/system/bin/init", new_argv, new_envp);
    }

    klog("<1>[HYBRID_ROUTER] FATAL: execve failed!\n");
    while (1) {
        sleep(10);
    }
    return 1;
}

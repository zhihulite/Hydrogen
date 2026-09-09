package com.hydrogen;

import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ScrollView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.LinearLayoutCompat;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.textview.MaterialTextView;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * 日志导出页：crash 目录打包 zip，经 SAF 另存到用户选择的位置。
 * hydrogen://logs 可从外部拉起。
 */
public class LogExportActivity extends AppCompatActivity {

    /** crash 目录名（CrashHandler 与 init_app 的 onError 落盘处）。 */
    public static final String CRASH_DIR = "crash";

    private static final int BUF_SIZE = 8192;
    private static final long PREVIEW_MAX_BYTES = 256 * 1024;

    private LinearLayoutCompat mListContainer;
    private ActivityResultLauncher<String> mSaveLauncher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        mSaveLauncher = registerForActivityResult(
                new ActivityResultContracts.CreateDocument("application/zip"), uri -> {
                    if (uri == null) return;
                    saveTo(uri);
                });
        setContentView(buildContentView());
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(android.R.id.content), (v, insets) -> {
            var bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom);
            return WindowInsetsCompat.CONSUMED;
        });
        refreshList();
    }

    // ==================== UI ====================

    private View buildContentView() {
        Context c = this;

        LinearLayoutCompat root = new LinearLayoutCompat(c);
        root.setOrientation(LinearLayoutCompat.VERTICAL);
        root.setLayoutParams(new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        MaterialToolbar toolbar = new MaterialToolbar(c);
        toolbar.setTitle("导出日志");
        toolbar.setNavigationOnClickListener(v -> finish());
        toolbar.setNavigationContentDescription("返回");
        root.addView(toolbar, new LinearLayoutCompat.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        mListContainer = new LinearLayoutCompat(c);
        mListContainer.setOrientation(LinearLayoutCompat.VERTICAL);
        int pad = dp(12);
        mListContainer.setPadding(pad, pad, pad, dp(24));
        ScrollView scroll = new ScrollView(c);
        scroll.setFillViewport(true);
        scroll.addView(mListContainer, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        root.addView(scroll, new LinearLayoutCompat.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        MaterialButton exportBtn = new MaterialButton(c);
        exportBtn.setText("导出崩溃日志压缩包");
        exportBtn.setOnClickListener(v -> export());
        LinearLayoutCompat.LayoutParams btnLp = new LinearLayoutCompat.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        btnLp.setMargins(pad, 0, pad, 0);
        root.addView(exportBtn, btnLp);

        MaterialTextView note = new MaterialTextView(c);
        note.setText("导出后崩溃日志将自动删除");
        note.setGravity(Gravity.CENTER);
        note.setTextSize(12);
        root.addView(note, new LinearLayoutCompat.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return root;
    }

    private void refreshList() {
        mListContainer.removeAllViews();
        List<File> files = listCrashFiles();

        if (files.isEmpty()) {
            MaterialTextView empty = new MaterialTextView(this);
            empty.setText("暂无崩溃日志\n应用崩溃后日志会出现在这里");
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(0, dp(64), 0, dp(64));
            mListContainer.addView(empty, new LinearLayoutCompat.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            return;
        }

        for (File f : files) {
            mListContainer.addView(buildFileRow(f));
        }
    }

    private View buildFileRow(File f) {
        Context c = this;

        LinearLayoutCompat row = new LinearLayoutCompat(c);
        row.setOrientation(LinearLayoutCompat.VERTICAL);
        row.setPadding(0, dp(10), 0, dp(10));
        row.setOnClickListener(v -> preview(f));

        MaterialTextView name = new MaterialTextView(c);
        name.setText(f.getName() + "  (" + formatSize(f.length()) + ")");
        name.setTextSize(15);
        row.addView(name);

        MaterialTextView summary = new MaterialTextView(c);
        String firstLine = readFirstLine(f);
        summary.setText(firstLine.isEmpty() ? "（空文件）" : firstLine);
        summary.setTextSize(13);
        summary.setMaxLines(2);
        row.addView(summary, new LinearLayoutCompat.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return row;
    }

    private void preview(File f) {
        StringBuilder sb = new StringBuilder();
        try (BufferedInputStream in = new BufferedInputStream(new FileInputStream(f))) {
            byte[] buf = new byte[BUF_SIZE];
            int n;
            long total = 0;
            while (total < PREVIEW_MAX_BYTES && (n = in.read(buf)) > 0) {
                sb.append(new String(buf, 0, n));
                total += n;
            }
            if (total >= PREVIEW_MAX_BYTES) sb.append("\n\n……（过长已截断）");
        } catch (IOException e) {
            sb.append("读取失败：").append(e);
        }
        ScrollView scroll = new ScrollView(this);
        MaterialTextView text = new MaterialTextView(this);
        text.setText(f.getName() + "\n\n" + sb);
        text.setTextIsSelectable(true);
        int pad = dp(16);
        text.setPadding(pad, pad, pad, pad);
        scroll.addView(text, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        new MaterialAlertDialogBuilder(this)
                .setTitle("日志预览")
                .setView(scroll)
                .setPositiveButton("关闭", null)
                .show();
    }

    // ==================== 导出 ====================

    /** 先弹 SAF 另存为，选中后打包写入目标。 */
    private void export() {
        List<File> files = listCrashFiles();
        if (files.isEmpty()) {
            Toast.makeText(this, "没有可导出的日志", Toast.LENGTH_SHORT).show();
            return;
        }
        String stamp = new SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(new Date());
        mSaveLauncher.launch("hydrogen-logs-" + stamp + ".zip");
    }

    /** 打包 crash 目录写入 SAF 目标，成功后清空 crash 目录。 */
    private void saveTo(Uri target) {
        List<File> files = listCrashFiles();
        if (files.isEmpty()) return;
        try (ZipOutputStream zos = wrapSafStream(target)) {
            byte[] buf = new byte[BUF_SIZE];
            for (File f : files) {
                zos.putNextEntry(new ZipEntry(f.getName()));
                try (BufferedInputStream in = new BufferedInputStream(new FileInputStream(f))) {
                    int n;
                    while ((n = in.read(buf)) > 0) {
                        zos.write(buf, 0, n);
                    }
                }
                zos.closeEntry();
            }
            Toast.makeText(this, "导出完毕", Toast.LENGTH_SHORT).show();
            // 写入成功才清空：保存失败时日志留在原地，可再次导出
            clearCrashDir(files);
            refreshList();
        } catch (IOException e) {
            Toast.makeText(this, "保存失败：" + e.getMessage(), Toast.LENGTH_LONG).show();
        }
    }

    private void clearCrashDir(List<File> files) {
        for (File f : files) {
            if (!f.delete()) {
                f.deleteOnExit();
            }
        }
    }

    private ZipOutputStream wrapSafStream(Uri target) throws IOException {
        OutputStream out = getContentResolver().openOutputStream(target, "wt");
        if (out == null) throw new IOException("openOutputStream returned null");
        return new ZipOutputStream(out);
    }

    private List<File> listCrashFiles() {
        File crashDir = new File(getExternalFilesDir(null), CRASH_DIR);
        File[] arr = crashDir.listFiles();
        if (arr == null) return Collections.emptyList();
        List<File> files = new ArrayList<>(Arrays.asList(arr));
        Collections.sort(files, (a, b) -> Long.compare(b.lastModified(), a.lastModified()));
        return files;
    }

    // ==================== 工具 ====================

    private int dp(int v) {
        return Math.round(v * getResources().getDisplayMetrics().density);
    }

    private static String formatSize(long bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return String.format(Locale.US, "%.1f KB", bytes / 1024f);
        return String.format(Locale.US, "%.1f MB", bytes / 1024f / 1024f);
    }

    private static String readFirstLine(File f) {
        try (BufferedInputStream in = new BufferedInputStream(new FileInputStream(f))) {
            StringBuilder sb = new StringBuilder();
            int b;
            int limit = 200;
            while (sb.length() < limit && (b = in.read()) != -1) {
                if (b == '\n') break;
                sb.append((char) b);
            }
            return sb.toString().trim();
        } catch (IOException e) {
            return "";
        }
    }
}

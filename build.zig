const std = @import("std");

/// この関数は命令形に見えるが、その仕事は外部ランナーによって実行さ
/// れるビルド・グラフを宣言的に構築することである。
pub fn build(b: *std.Build) void {

    // 標準ターゲットオプションは、`zig build`を実行する人がビルドす
    // るターゲットを選択できるようにするものである。ここではデフォ
    // ルトを上書きしない。つまり、どのターゲットでも許可され、デフ
    // ォルトはネイティブである。サポートされるターゲットセットを制
    // 限するための他のオプションも利用可能である。
    const target = b.standardTargetOptions(.{});

    // 標準の最適化オプションでは、`zig build`を実行する人がDebug、
    // ReleaseSafe、ReleaseFast、ReleaseSmallから選択できるようにな
    // っている。ここでは優先リリースモードを設定せず、ユーザーが最
    // 適化方法を決められるようにしています。
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "miniature-fiesta",
        // この場合、メイン・ソース・ファイルは単なるパスだが、より
        // 複雑なビルド・スクリプトでは、これは生成されたファイルに
        // なる。
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // これは、ユーザが "install "ステップ（`zig build`を実行したと
    // きのデフォルトのステップ）を起動したときに、実行ファイルを標
    // 準の場所にインストールする意図を宣言するものである。
    b.installArtifact(exe);

    // これは、ビルドグラフにRunステップを*作成*し、それに依存する別
    // のステップが評価されたときに実行されるようにする。次の行で、
    // そのような依存関係を確立する。
    const run_cmd = b.addRunArtifact(exe);

    // 実行ステップをインストール・ステップに依存させることで、キャ
    // ッシュ・ディレクトリ内から直接実行するのではなく、インストー
    // ル・ディレクトリから実行するようになります。これは必須ではあ
    // りませんが、アプリケーションがインストールされた他のファイル
    // に依存している場合は、このようにすることで、それらが確実に存
    // 在し、期待される場所にあるようになります。
    run_cmd.step.dependOn(b.getInstallStep());

    // これにより、ユーザーはビルドの際にアプリケーションに引数を渡
    // すことができる。コマンドの中でアプリケーションに引数を渡すこ
    // とができる： `zig build run -- arg1 arg2 etc`.
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // これでビルドステップが作成される。これは `zig build --help`
    // メニューに表示され、次のように選択できる： zig build run`
    // これはデフォルトの "install"ではなく、`run`ステップを評価する。
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // ユニットテスト用のステップを作成します。これはテストの実行
    // ファイルをビルドするだけで、実行はしません。
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // 先ほどの run ステップの作成と同様に、これは `zig build --help`
    // メニューに `test` ステップを公開し、ユーザーがユニットテス
    // トの実行を要求する方法を提供する。
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

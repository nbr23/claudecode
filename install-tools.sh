#!/usr/bin/env bash
set -euo pipefail

: "${APKTOOL_VERSION:?}" "${JADX_VERSION:?}" "${BUNDLETOOL_VERSION:?}" "${GHIDRA_VERSION:?}"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
install_dir=/opt/reversing
mkdir -p "$install_dir/bin"

curl -fsSL --retry 3 "https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar" -o "$install_dir/apktool.jar"
curl -fsSL --retry 3 "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" -o "$work_dir/jadx.zip"
unzip -q "$work_dir/jadx.zip" -d "$install_dir/jadx"
curl -fsSL --retry 3 "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar" -o "$install_dir/bundletool.jar"

for tool in apktool bundletool; do
    printf '#!/usr/bin/env bash\nset -euo pipefail\nexec java -jar /opt/reversing/%s.jar "$@"\n' "$tool" > "$install_dir/bin/$tool"
    chmod +x "$install_dir/bin/$tool"
done

curl -fsSL --retry 3 "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/tags/${GHIDRA_VERSION}" -o "$work_dir/ghidra-release.json"
asset=$(jq -er '[.assets[] | select(.name | startswith("ghidra_") and contains("_PUBLIC_") and endswith(".zip"))] | if length == 1 then .[0] else error("Expected one Ghidra release archive") end' "$work_dir/ghidra-release.json")
url=$(jq -er '.browser_download_url' <<< "$asset")
digest=$(jq -er '.digest | select(startswith("sha256:")) | ltrimstr("sha256:")' <<< "$asset")
curl -fsSL --retry 3 "$url" -o "$work_dir/ghidra.zip"
printf '%s  %s\n' "$digest" "$work_dir/ghidra.zip" | sha256sum -c -
unzip -q "$work_dir/ghidra.zip" -d "$work_dir/ghidra"
mv "$work_dir"/ghidra/ghidra_*_PUBLIC "$install_dir/ghidra"

case "$(uname -m)" in
    x86_64) native_platform=linux_x86_64 ;;
    aarch64) native_platform=linux_arm_64 ;;
    *) exit 1 ;;
esac

decompiler_dir="$install_dir/ghidra/Ghidra/Features/Decompiler"
cpp_dir="$decompiler_dir/src/decompile/cpp"
make -C "$cpp_dir" -j2 ghidra_opt ARCH_TYPE=
make -C "$cpp_dir" -j2 sleigh_opt ARCH_TYPE=
mkdir -p "$decompiler_dir/os/$native_platform"
install -m 755 "$cpp_dir/ghidra_opt" "$decompiler_dir/os/$native_platform/decompile"
install -m 755 "$cpp_dir/sleigh_opt" "$decompiler_dir/os/$native_platform/sleigh"
make -C "$cpp_dir" clean

demangler_dir="$install_dir/ghidra/GPL/DemanglerGnu"
mkdir -p "$demangler_dir/os/$native_platform"
for version in 24 41; do
    source_dir="$demangler_dir/src/demangler_gnu_v2_$version"
    flags=()
    if [[ "$version" == 24 ]]; then
        flags+=(-DMAIN_CPLUS_DEM)
    fi
    gcc -O2 -std=gnu17 -DHAVE_STDLIB_H -DHAVE_STRING_H "${flags[@]}" \
        -I "$source_dir/headers" "$source_dir"/c/*.c \
        -o "$demangler_dir/os/$native_platform/demangler_gnu_v2_$version"
    printf '_Z3foov\n' | "$demangler_dir/os/$native_platform/demangler_gnu_v2_$version" | grep -Fx 'foo()'
done

fileformats_dir="$install_dir/ghidra/Ghidra/Features/FileFormats"
mkdir -p "$fileformats_dir/os/$native_platform"
gcc -O2 "$fileformats_dir"/src/lzfse/c/*.c -o "$fileformats_dir/os/$native_platform/lzfse"

ln -s ../ghidra/ghidraRun "$install_dir/bin/ghidra"
export PATH="$install_dir/bin:$install_dir/jadx/bin:$install_dir/ghidra/support:$PATH"
apktool --version
jadx --version
bundletool version

printf 'int main(void) { return 0; }\n' > "$work_dir/smoke.c"
gcc "$work_dir/smoke.c" -o "$work_dir/smoke"
cat > "$work_dir/DecompilerSmoke.java" <<'JAVA'
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
public class DecompilerSmoke extends GhidraScript {
    public void run() throws Exception {
        DecompInterface decompiler = new DecompInterface();
        try {
            if (!decompiler.openProgram(currentProgram)) {
                throw new IllegalStateException("Cannot open program");
            }
            var function = currentProgram.getFunctionManager().getFunctions(true).next();
            var result = decompiler.decompileFunction(function, 30, monitor);
            if (!result.decompileCompleted()) {
                throw new IllegalStateException(result.getErrorMessage());
            }
            println("DECOMPILER_SMOKE_OK");
        } finally {
            decompiler.dispose();
        }
    }
}
JAVA
analyzeHeadless "$work_dir" smoke-project -import "$work_dir/smoke" \
    -scriptPath "$work_dir" -postScript DecompilerSmoke.java -deleteProject \
    > "$work_dir/ghidra-smoke.log" 2>&1 || { cat "$work_dir/ghidra-smoke.log"; exit 1; }
cat "$work_dir/ghidra-smoke.log"
grep -q DECOMPILER_SMOKE_OK "$work_dir/ghidra-smoke.log"

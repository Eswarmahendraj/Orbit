import subprocess, sys, os

os.chdir(r"D:\AURA_App")
result = subprocess.run(
    ["git", "push", "origin", "main"],
    capture_output=True, text=True
)

output = "=== STDOUT ===\n" + result.stdout + "\n=== STDERR ===\n" + result.stderr + "\n=== Return code: " + str(result.returncode) + " ==="
with open(r"D:\AURA_App\push_result.txt", "w") as f:
    f.write(output)

print(output)
input("Press Enter to close...")

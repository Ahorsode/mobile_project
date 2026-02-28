import sys
import os
import runpy
import time
import builtins

# Redirect stdout and stderr to a file
log_file_path = os.path.join(os.environ.get("USER_CODE_DIR", "."), "output.log")
sys.stdout = open(log_file_path, "w", buffering=1)
sys.stderr = sys.stdout

def mocked_input(prompt=""):
    if prompt:
        print(prompt, end="", flush=True)
    
    user_code_dir = os.environ.get("USER_CODE_DIR", ".")
    lock_file = os.path.join(user_code_dir, "input.lock")
    input_file = os.path.join(user_code_dir, "input.txt")
    
    # 1. Create lock file to signal Flutter
    with open(lock_file, "w") as f:
        f.write("request")
    
    # 2. Wait for Flutter to write to input.txt
    while not os.path.exists(input_file):
        time.sleep(0.05)
    
    # 3. Read the input and cleanup
    with open(input_file, "r") as f:
        data = f.read().strip()
    
    # 4. Echo the input back to stdout so it persists in the log
    print(data)
    
    if os.path.exists(lock_file):
        os.remove(lock_file)
    if os.path.exists(input_file):
        os.remove(input_file)
        
    return data


# Override the built-in input function
builtins.input = mocked_input

def main():
    user_code_path = os.path.join(os.environ.get("USER_CODE_DIR", "."), "user_script.py")
    
    if not os.path.exists(user_code_path):
        print("Error: user_script.py not found.")
        return

    try:
        # execute the user's code
        runpy.run_path(user_code_path, run_name="__main__")
    except Exception as e:
        print(e)

if __name__ == "__main__" or __name__ == "main":
    main()


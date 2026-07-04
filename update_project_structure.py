import os
import shutil

def main():
    print("=== Cập nhật cấu trúc thư mục dự án theo mô hình mới ===")
    
    workspace_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 1. Định nghĩa các thư mục mới cần tạo
    new_dirs = [
        os.path.join("data", "raw_files"),
        os.path.join("database", "ddl"),
        "pipelines",
        "analytics-api",
        "dashboard",
        "ai-agent",
        "notebooks"
    ]
    
    for folder in new_dirs:
        path = os.path.join(workspace_dir, folder)
        if not os.path.exists(path):
            os.makedirs(path)
            print(f"Đã tạo thư mục: {folder}/")
            
    # 2. Di chuyển các file CSV từ data_lake/ sang data/raw_files/
    old_data_lake = os.path.join(workspace_dir, "data_lake")
    new_raw_files = os.path.join(workspace_dir, "data", "raw_files")
    
    if os.path.exists(old_data_lake):
        print("\n=== Đang di chuyển dữ liệu từ data_lake/ sang data/raw_files/ ===")
        for file_name in os.listdir(old_data_lake):
            src_file = os.path.join(old_data_lake, file_name)
            dest_file = os.path.join(new_raw_files, file_name)
            if os.path.isfile(src_file):
                shutil.copy2(src_file, dest_file)
                print(f" -> Đã chuyển {file_name}")
        # Xóa thư mục cũ
        try:
            shutil.rmtree(old_data_lake)
            print("Đã dọn dẹp thư mục cũ: data_lake/")
        except Exception as e:
            print(f"Không thể xóa thư mục cũ data_lake: {e}")
            
    # 3. Dọn dẹp các thư mục trống cũ (nếu có)
    old_folders = ["staging", "warehouse", "workflows"]
    for folder in old_folders:
        path = os.path.join(workspace_dir, folder)
        if os.path.exists(path):
            try:
                shutil.rmtree(path)
                print(f"Đã dọn dẹp thư mục cũ: {folder}/")
            except Exception as e:
                print(f"Không thể xóa thư mục cũ {folder}: {e}")

    print("\nCập nhật cấu trúc thư mục thành công!")

if __name__ == "__main__":
    main()

import os
import shutil

def main():
    print("=== Khởi tạo cấu trúc thư mục học tập Data Engineering ===")
    
    # 1. Định nghĩa các thư mục cần tạo
    workspace_dir = os.path.dirname(os.path.abspath(__file__))
    dirs_to_create = [
        "data_lake",
        "staging",
        "warehouse",
        "workflows"
    ]
    
    for folder in dirs_to_create:
        path = os.path.join(workspace_dir, folder)
        if not os.path.exists(path):
            os.makedirs(path)
            print(f"Đã tạo thư mục: {folder}/")
        else:
            print(f"Thư mục đã tồn tại: {folder}/")
            
    # 2. Sao chép dữ liệu giả lập vào data_lake
    src_dataset_dir = os.path.join(workspace_dir, "fnb_15_branches_synthetic_dataset")
    dest_data_lake = os.path.join(workspace_dir, "data_lake")
    
    if os.path.exists(src_dataset_dir):
        print("\n=== Đang sao chép các file CSV thô vào data_lake/ ===")
        for file_name in os.listdir(src_dataset_dir):
            if file_name.endswith(".csv") or file_name == "README.md":
                src_file = os.path.join(src_dataset_dir, file_name)
                dest_file = os.path.join(dest_data_lake, file_name)
                shutil.copy2(src_file, dest_file)
                print(f" -> Đã copy {file_name} vào data_lake/")
        print("Đã hoàn thành chuẩn bị Data Lake thô!")
    else:
        print(f"\n[Cảnh báo] Không tìm thấy thư mục nguồn dữ liệu thô tại: {src_dataset_dir}")
        print("Vui lòng đảm bảo thư mục fnb_15_branches_synthetic_dataset/ nằm ở root workspace.")

if __name__ == "__main__":
    main()

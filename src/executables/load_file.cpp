#include <iostream>
#include <abb_librws/rws_interface.h>
#include <Poco/Net/Context.h>
#include <fstream>
#include <sstream>
#include <string>
#include <thread>
#include <chrono>

// Reads an entire file into a std::string
std::string readFileAsString(const std::string& filepath)
{
  std::ifstream file(filepath, std::ios::in | std::ios::binary);
  if (!file)
  {
    throw std::runtime_error("Failed to open file: " + filepath);
  }

  std::ostringstream contents;
  contents << file.rdbuf();
  return contents.str();
}


int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        std::cerr << "Usage: rosrun abb_librws load_file <controller_file_name> [task_name] [file_path]" << std::endl;
        return 1;
    }

    std::string task_name = "T_ROB1";  // Default task name
    // default file path for rapid programs
    std::string original_file_path = "/root/catkin_ws/src/abb_wrapper/abb_librws/src/executables/rapid_programs/";
    
    if (argc >= 3)
    {
      task_name = argv[2];  // Override if provided
    }

    if (argc >= 4)
    {
      original_file_path = argv[3];
    }

    
    std::string controller_file_name = argv[1];

    std::string original_file_name = controller_file_name;
    std::string ip = "192.168.15.81";
    std::string username = "Admin";
    std::string password = "robotics";
    std::string controller_file_path = "Home/Programs/Wizard";

    // Create Poco SSL context with no verification (self-signed certs likely)
    const Poco::Net::Context::Ptr ptrContext(new Poco::Net::Context( Poco::Net::Context::CLIENT_USE, "", "", "", Poco::Net::Context::VERIFY_NONE));

    // Create RWS interface
    abb::rws::RWSInterface rws_interface(ip, username, password, ptrContext);

    // Turn off existing processes
    std::cout << "program off: " << rws_interface.stopRAPIDExecution() << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Upload/overwrite mod file
    std::string file_content = readFileAsString(original_file_path + original_file_name + ".mod");
    abb::rws::RWSClient::FileResource upload_resource(controller_file_name + ".mod", controller_file_path);
    std::cout << "upload mod file: " << rws_interface.uploadFile(upload_resource, file_content) << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Upload/overwrite program file
    std::string program_file_content = readFileAsString(original_file_path + original_file_name + ".pgf");
    abb::rws::RWSClient::FileResource program_upload_resource(controller_file_name + ".pgf", controller_file_path);
    std::cout << "upload program file: " << rws_interface.uploadFile(program_upload_resource, program_file_content) << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Request MasterShip (Required to manage rapid tasks)
    std::cout << "requesting mastership: " << rws_interface.requestMasterShip() << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(100));


    // unload rapid task
    std::cout << "unload task file: " << rws_interface.unloadFileFromRapid(task_name) << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // loading rapid task
    abb::rws::RWSClient::FileResource program(controller_file_name + ".pgf", controller_file_path);
    std::cout << "load file to task: " << rws_interface.loadFileToRapid(program, task_name) << std::endl; 
    std::this_thread::sleep_for(std::chrono::milliseconds(100)); 
    
    // release MasterShip
    std::cout << "releasing mastership: " << rws_interface.releaseMasterShip() << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    return 0;
}

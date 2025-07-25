#include <iostream>
#include <abb_librws/rws_interface.h>
#include <Poco/Net/Context.h>
#include <fstream>
#include <sstream>
#include <string>
#include <thread>
#include <chrono>
#include <unordered_map>


int main(int argc, char* argv[])
{
    std::string event_code_path = "/root/abb_librws/docs/event_codes/event_log_lookup.csv";
    if (argc >= 2)
    {
        if (std::string(argv[1]) == "full")
        {
            event_code_path = "/root/abb_librws/docs/event_codes/event_log_lookup_full.csv";
            std::cout << "hi";
        }
    }

    std::string ip = "192.168.15.81";
    std::string username = "Admin";
    std::string password = "robotics";

    std::string task_name = "T_ROB1";  // Default task name
    // default file path for rapid programs
    std::string original_file_path = "/root/abb_librws/src/executables/rapid_programs";
    std::string controller_file_name = "motion";

    std::string original_file_name = controller_file_name;
    std::string controller_file_path = "Home/Programs/Wizard";
    std::unordered_map<std::string, std::string> codeDescriptions;


    // Create Poco SSL context with no verification (self-signed certs likely)
    const Poco::Net::Context::Ptr ptrContext(new Poco::Net::Context( Poco::Net::Context::CLIENT_USE, "", "", "", Poco::Net::Context::VERIFY_NONE));
    
    // Create RWS interface
    abb::rws::RWSInterface rws_interface(ip, username, password, ptrContext);

    // generate event log description map
    std::ifstream file(event_code_path);
    std::string line;

    while (std::getline(file, line))
    {
        std::istringstream iss(line);
        std::string code, description;

        if (std::getline(iss, code, ',') && std::getline(iss, description))
        {
            codeDescriptions[code] = description;
        }
    }

    // prints elogs
    rws_interface.getELog(codeDescriptions);

}

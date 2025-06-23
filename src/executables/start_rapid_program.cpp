#include <iostream>
#include <abb_librws/rws_interface.h>
#include <Poco/Net/Context.h>
#include <thread>
#include <chrono>

int main()
{
    std::string ip = "192.168.15.81";
    std::string username = "Admin";
    std::string password = "robotics";

    // Can only connect locally through MGMT, required to change operating mode
    bool attempt_local_connect = false;

    // Create Poco SSL context with no verification (self-signed certs likely)
    const Poco::Net::Context::Ptr ptrContext(new Poco::Net::Context( Poco::Net::Context::CLIENT_USE, "", "", "", Poco::Net::Context::VERIFY_NONE));
    
    // Create RWS interface
    abb::rws::RWSInterface rws_interface(ip, username, password, ptrContext);

    // Turn off existing processes
    std::cout << "program off: " << std::endl;
    rws_interface.stopRAPIDExecution();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    if (attempt_local_connect) {
        std::cout << "requesting local user registration: " << rws_interface.registerLocalUser("Admin", "ExternalApplication", "ExternalLocation") << std::endl;
        std::cout << "set to auto mode: " << rws_interface.setAutoMode() << std::endl;
    }

    // turn motors on
    std::cout << "set motors on: " << std::endl;
    rws_interface.setMotorsOn();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Request MasterShip (Required to reset program pointer)
    std::cout << "requesting mastership: " << std::endl;
    rws_interface.requestMasterShip();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    std::cout << "reset pointer to main status: " << std::endl;
    rws_interface.resetRAPIDProgramPointer();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    std::cout << "releasing mastership: " << std::endl;
    rws_interface.releaseMasterShip();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // start program
    std::cout << "program on: " << std::endl;
    rws_interface.startRAPIDExecution();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));


    return 0;
}


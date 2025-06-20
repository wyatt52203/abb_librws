#include <iostream>
#include <abb_librws/rws_interface.h>
#include <Poco/Net/Context.h>

int main()
{
    std::string ip = "192.168.15.81";
    std::string username = "Admin";
    std::string password = "robotics";

    // Create Poco SSL context with no verification (self-signed certs likely)
    const Poco::Net::Context::Ptr ptrContext(new Poco::Net::Context( Poco::Net::Context::CLIENT_USE, "", "", "", Poco::Net::Context::VERIFY_NONE));

    // Create RWS interface
    abb::rws::RWSInterface rws_interface(ip, username, password, ptrContext);

    // Turn off existing processes
    std::cout << "program off: " << rws_interface.stopRAPIDExecution() << std::endl;

    return 0;
}

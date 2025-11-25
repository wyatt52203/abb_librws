MODULE control_tcp
    VAR socketdev server_socket;
    VAR socketdev client_socket;
    VAR string server_ip;
    VAR num server_port;
    VAR string msg;
    VAR string cmd;
    VAR bool receive_success;
    VAR bool accept_success;
    VAR bool listening;
    VAR bool receiving;

    PERS num spd;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num x_target;
    PERS num y_target;
    PERS num z_target;
    
    PROC main()
        ! Reset params
        SetDO MyResetSignal, 0;
        SetDO MyEmergencyStopSignal, 0;
        SetDO MyPauseSignal, 0;
        SetDO MyContinueSignal, 0;

        ! delete old connections
        SocketClose server_socket;
        SocketClose client_socket;

        ! Set connection parameters
        server_ip := "192.168.15.82";
        server_port := 2002;

        SocketCreate server_socket;
        SocketBind server_socket, server_ip, server_port;
        SocketListen server_socket;

        listening := TRUE;
        receiving := FALSE;

        !receive   
        WHILE TRUE DO

            IF listening THEN
                accept_success := TRUE;
                SocketAccept server_socket, client_socket;
                IF accept_success THEN
                    listening := FALSE;
                    receiving := TRUE;
                ENDIF
            ENDIF

            IF receiving THEN
                receive_success := TRUE;
                SocketReceive client_socket \Str := msg;
                
                !recieve_sucess gets set to false if socketReceive error handler is called
                IF receive_success THEN
                    cmd := StrPart(msg, 1, 3);

                    TEST cmd
                        CASE "pz!":
                            SetDO MyPauseSignal, 1;
                        CASE "pl!":
                            SetDO MyContinueSignal, 1;
                        CASE "rs!":
                            SetDO MyResetSignal, 1;
                        CASE "rsd":
                            PERS num spd := 800;
                            PERS num acc := 100;
                            PERS num jrk := 100;
                            PERS num dac := 100;
                            PERS zonedata zone := fine;
                            PERS speeddata speed := [800, 1000, 5000, 1000];
                            PERS num x_target := 300;
                            PERS num y_target := -450;
                            PERS num z_target := 700;

                            
                            SetDO MyResetSignal, 1;
                        CASE "emr":
                            SetDO MyEmergencyStopSignal, 1;
                    ENDTEST

                ENDIF
            ENDIF

        ENDWHILE        
   

        ERROR
            IF ERRNO = ERR_SOCK_TIMEOUT THEN
                IF listening THEN
                    accept_success := FALSE;
                    TRYNEXT;
                ELSEIF receiving THEN
                    receive_success := FALSE;
                    TRYNEXT;
                ENDIF
            ENDIF

            IF ERRNO = ERR_SOCK_CLOSED THEN
                ExitCycle;
            ENDIF

        SocketClose server_socket;
        SocketClose client_socket;
        
    ENDPROC    
    
ENDMODULE

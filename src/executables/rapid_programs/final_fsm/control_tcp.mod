MODULE command_tcp
    VAR socketdev server_socket;
    VAR socketdev client_socket;
    VAR string server_ip;
    VAR num server_port;
    VAR string msg;
    VAR string cmd;
    VAR bool receive_success;
    VAR bool accept_success;
    VAR string response_msg;
    VAR bool listening;
    VAR bool receiving;

    
    ! Shared Params
    PERS bool go;

    PERS num state;
    ! STATE DEFINITION
    ! 0 = IDLE
    ! 1 = RUNNING
    ! 2 = PAUSED
    ! 3 = ABORTED
    
    PROC main()
        ! Reset params
        go := FALSE;
        send := FALSE;
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

                    response_msg := msg;

                    TEST cmd
                        CASE "go!":
                            IF state = 0 THEN
                                go := TRUE;
                            ENDIF
                        CASE "pz!":
                            SetDO MyPauseSignal, 1;
                        CASE "pl!":
                            SetDO MyContinueSignal, 1;
                        CASE "rs!":
                            SetDO MyResetSignal, 1;
                        CASE "emr":
                            SetDO MyEmergencyStopSignal, 1;
                    ENDTEST

                ELSE
                    response_msg := "no message recieved";
                ENDIF

                IF send THEN

                    send := FALSE;
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

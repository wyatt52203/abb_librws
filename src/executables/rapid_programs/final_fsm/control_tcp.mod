MODULE control_tcp
    PERS socketdev ctrl_server_socket;
    PERS socketdev ctrl_client_socket;
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

    PERS bool fsm_channels_live;

    PERS socketdev status_client_socket;
    PERS socketdev status_server_socket;
    PERS socketdev cmd_client_socket;
    PERS socketdev cmd_server_socket;

    FUNC socket_status_check()
        VAR socketdev all_sockets{6} := [ctrl_client_socket, ctrl_server_socket, status_client_socket, status_server_socket, cmd_client_socket, cmd_server_socket];

        FOR idx FROM 1 to dim(all_sockets, 1) DO
            IF SOCKET_CONNECTED <> SocketGetStatus(all_sockets{idx}) THEN
                RETURN FALSE;

            ENDIF

        ENDFOR

        RETURN TRUE; 
    ENDFUNC

    PROC main()
        ! delete old connections
        SocketClose ctrl_server_socket;
        SocketClose ctrl_client_socket;

        ! Set connection parameters
        server_ip := GetSysInfo(\LanIp);
        server_port := 2002;

        SocketCreate ctrl_server_socket;
        SocketBind ctrl_server_socket, server_ip, server_port;
        SocketListen ctrl_server_socket;

        listening := TRUE;
        receiving := FALSE;

        !receive   
        WHILE TRUE DO
            WaitUntil fsm_channels_live;

            IF listening THEN
                accept_success := TRUE;
                SocketAccept ctrl_server_socket, ctrl_client_socket;
                IF accept_success THEN
                    listening := FALSE;
                    receiving := TRUE;
                ENDIF
            ENDIF

            IF receiving THEN
                receive_success := TRUE;
                SocketReceive ctrl_client_socket \Str := msg;
                
                !recieve_sucess gets set to false if socketReceive error handler is called
                IF receive_success THEN
                    cmd := StrPart(msg, 1, 3);

                    TEST cmd
                        CASE "pz!":
                            SetDO MyPauseSignal, 1;
                        CASE "pl!":
                            SetDO MyContinueSignal, 1;
                        CASE "rss":
                            IF state = 3 AND socket_status_check THEN
                                state := 0;
                                spd := 800;
                                acc := 100;
                                jrk := 100;
                                dac := 100;
                                zone := fine;
                                speed := [800, 1000, 5000, 1000];
                                x_target := 300;
                                y_target := -450;
                                z_target := 700;
                                state := 0;

                                SetDO MyResetSignal, 1;
                            ENDIF
                        CASE "rsp":
                            IF state = 2 OR state = 0 THEN
                                spd := 800;
                                acc := 100;
                                jrk := 100;
                                dac := 100;
                                zone := fine;
                                speed := [800, 1000, 5000, 1000];
                                x_target := 300;
                                y_target := -450;
                                z_target := 700;
                                state := 0;
                                SetDO MyResetSignal, 1;
                            ENDIF
                        CASE "rs!":
                            IF state = 2 OR state = 0 THEN
                                state := 0;
                                SetDO MyResetSignal, 1;
                            ENDIF
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

        SocketClose ctrl_server_socket;
        SocketClose ctrl_client_socket;
        
    ENDPROC    
    
ENDMODULE

MODULE control_tcp
    VAR socketdev ctrl_server_socket;
    VAR socketdev ctrl_client_socket;
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
    PERS num state;

    PERS bool fsm_channels_live;
    VAR bool ctrl_channel_health;

    PERS bool status_channel_health;
    PERS bool cmd_channel_health;

    FUNC bool socket_status_check()
        RETURN ctrl_channel_health AND cmd_channel_health AND status_channel_health;
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
        ctrl_channel_health := FALSE;

        !receive   
        WHILE TRUE DO
            IF fsm_channels_live THEN
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
                                IF state = 3 AND socket_status_check() THEN
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
            ENDIF

            VAR socketstatus test_status := SocketGetStatus(ctrl_client_socket);
            ctrl_channel_health := SOCKET_CONNECTED = SocketGetStatus(ctrl_client_socket) AND SOCKET_CONNECTED = SocketGetStatus(ctrl_server_socket);

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

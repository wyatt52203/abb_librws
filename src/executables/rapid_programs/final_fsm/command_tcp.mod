MODULE command_tcp
    VAR socketdev cmd_server_socket;
    VAR socketdev cmd_client_socket;
    VAR string server_ip;
    VAR num server_port;
    VAR string msg;
    VAR string cmd;
    VAR string value;
    VAR num str_length;
    VAR num parsed_val;
    VAR bool parse_success;
    VAR bool receive_success;
    VAR bool accept_success;
    VAR bool listening;
    VAR bool receiving;


    
    ! Shared Params
    PERS num spd;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;


    PERS num x_read;
    PERS num y_read;
    PERS num z_read;
    PERS num x_target;
    PERS num y_target;
    PERS num z_target;

    PERS num state;
    ! STATE DEFINITION
    ! 0 = IDLE
    ! 1 = RUNNING
    ! 2 = PAUSED
    ! 3 = ABORTED

    PERS bool awaiting_motion;
    PERS bool motion_complete;
    PERS bool fsm_channels_live;
    PERS bool cmd_channel_health;


    PROC EnforceBounds(INOUT num x, INOUT num y, INOUT num z)
        ! Enforce Y bounds [-450, 450]

        ! +750 height in safety, 700 here
        ! -250 height - soft, -350 safety config

        ! left side -500 safety config 
        ! software -450

        ! right side safety 550
        ! software 450

        IF y > 450 THEN
            y := 450;
        ELSEIF y < -450 THEN
            y := -450;
        ENDIF

        ! Enforce Z bounds [10, 850]
        IF z > 700 THEN
            z := 700;
        ELSEIF z < -250 THEN
            z := -250;
        ENDIF

        IF x > 450 THEN
            x := 450;
        ELSEIF x < 250 THEN
            x := 250;
        ENDIF
    ENDPROC
    
    PROC main()
        ! Reset params
        go := FALSE;

        ! delete old connections
        SocketClose cmd_server_socket;
        SocketClose cmd_client_socket;

        ! Set connection parameters
        server_ip := GetSysInfo(\LanIp);
        server_port := 2000;

        SocketCreate cmd_server_socket;
        SocketBind cmd_server_socket, server_ip, server_port;
        SocketListen cmd_server_socket;

        listening := TRUE;
        receiving := FALSE;
        awaiting_motion := FALSE;
        cmd_channel_health := FALSE;

        !receive   
        WHILE TRUE DO
            IF fsm_channels_live THEN
                IF listening THEN
                    accept_success := TRUE;
                    SocketAccept cmd_server_socket, cmd_client_socket;
                    IF accept_success THEN
                        listening := FALSE;
                        receiving := TRUE;
                    ENDIF
                ENDIF

                IF receiving THEN
                    receive_success := TRUE;
                    SocketReceive cmd_client_socket \Str := msg;
                    
                    !recieve_sucess gets set to false if socketReceive error handler is called
                    if receive_success THEN
                        cmd := StrPart(msg, 1, 3);
                        str_length := StrLen(msg);
                        ! Extracts (str_length - 4) total characters, starting at 5
                        value := StrPart(msg, 5, (str_length - 4));
                        parse_success := StrToVal(value, parsed_val);

                        if parse_success THEN
                            TEST cmd
                                CASE "go!":
                                    IF state = 0 THEN
                                        go := TRUE;
                                        awaiting_motion := TRUE;
                                        receiving := FALSE;
                                        motion_complete := FALSE;
                                    ENDIF
                                CASE "spd":
                                    spd := parsed_val;
                                    speed := [spd, 1000, 5000, 1000];
                                CASE "zon":
                                    TEST parsed_val
                                        CASE 1000:
                                            zone := fine;
                                        CASE 0:
                                            zone := z0;
                                        CASE 20:
                                            zone := z20;
                                        CASE 50:
                                            zone := z50;
                                        CASE 100:
                                            zone := z100;
                                        CASE 150:
                                            zone := z150;
                                        CASE 200:
                                            zone := z200;
                                    ENDTEST
                                CASE "acc":
                                    acc := parsed_val;
                                CASE "jrk":
                                    jrk := parsed_val;
                                CASE "dac":
                                    dac := parsed_val;
                                CASE "xtg":
                                    x_target := parsed_val;
                                CASE "ytg":
                                    y_target := parsed_val;
                                CASE "ztg":
                                    z_target := parsed_val;
                            ENDTEST

                            EnforceBounds x_target, y_target, z_target;
                        ENDIF
                    ENDIF
                ENDIF

                IF awaiting_motion AND motion_complete THEN
                    SocketSend cmd_client_socket \Str := "Complete";
                    awaiting_motion := FALSE;
                    motion_complete := FALSE;
                    receiving := TRUE;
                ELSEIF awaiting_motion AND state = 0 THEN
                    awaiting_motion := FALSE;
                    receiving := TRUE;
                ENDIF
            ENDIF

            IF SOCKET_CONNECTED = SocketGetStatus(ctrl_client_socket) AND SOCKET_CONNECTED = SocketGetStatus(ctrl_server_socket) THEN
                ctrl_channel_health := TRUE;
            ELSE
                ctrl_channel_health := FALSE;
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


        SocketClose cmd_server_socket;
        SocketClose cmd_client_socket;
        
    ENDPROC    
    
ENDMODULE

MODULE udp_receiver
    VAR socketdev udp_socket;
    VAR socketstatus status;
    VAR string client_ip;
    VAR num client_port;
    VAR string msg;
    VAR string cmd;
    VAR string value;
    VAR num str_length;
    VAR num parsed_val;
    VAR bool success;


    
    ! web params
    PERS num spd;
    PERS num int;
    PERS num lft;
    PERS num rgt;
    PERS num upr;
    PERS num lwr;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS bool go;
    PERS bool play;
    PERS zonedata zone;
    PERS speeddata speed;
    
    
    
    PROC main()
        ! Reset params

        spd := 800;
        int := 100;
        lft := -600;
        rgt := 600;
        upr := 850;
        lwr := 250;
        acc := 100;
        jrk := 100;
        dac := 100;
        go := FALSE;
        play := TRUE;
        zone := [TRUE,0,0,0,0,0,0];
        speed := [800,1000,5000,1000];
        SetDO MyPauseSignal, 0;
        SetDO MyResetSignal, 0;

        ! delete old connections
        ! SocketClose udp_socket;

        SocketCreate udp_socket \UDP;
        SocketBind udp_socket, "192.168.15.102", 1025;

        TPWrite "UDP server ready.";


        !receive   
        WHILE TRUE DO
            SocketReceiveFrom udp_socket \Str := msg, client_ip, client_port;
            
            TPWrite "msg: " + msg;
            cmd := StrPart(msg, 1, 3);
            TPWrite "cmd: " + cmd;
            str_length := StrLen(msg);
            value := StrPart(msg, 5, (str_length - 4));
            TPWrite "val: " + value;
            success := StrToVal(value, parsed_val);

            if success THEN
                TEST cmd
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
                    CASE "int":
                        int := parsed_val;
                    CASE "lft":
                        lft := parsed_val;
                    CASE "rgt":
                        rgt := parsed_val;
                    CASE "upr":
                        upr := parsed_val;
                    CASE "lwr":
                        lwr := parsed_val;
                    CASE "acc":
                        acc := parsed_val;
                    CASE "jrk":
                        jrk := parsed_val;
                    CASE "dac":
                        dac := parsed_val;
                    CASE "go!":
                        go := TRUE;
                    CASE "pz!":
                        play := FALSE;
                        SetDO MyPauseSignal, 1;
                    CASE "pl!":
                        play := TRUE;
                    CASE "rs!":
                        SetDO MyResetSignal, 1;
                ENDTEST
            ENDIF
        ENDWHILE        

        ERROR
            TPWrite "ERRNO: " + ValToStr(ERRNO);
            IF ERRNO = ERR_SOCK_TIMEOUT THEN
                RETRY;
            ENDIF

        TPWrite "closing now";
        SocketClose udp_socket;
        
    ENDPROC


    
    
ENDMODULE




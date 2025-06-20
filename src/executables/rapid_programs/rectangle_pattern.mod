MODULE rectangle_pattern
    VAR socketdev udp_socket;
    VAR string client_ip;
    VAR num client_port;
    VAR string msg;
    VAR string cmd;
    VAR string value;
    VAR num str_length;
    VAR num parsed_val;
    VAR bool success;
    VAR speeddata speed := v100;
    VAR bool left_to_right := TRUE;
    VAR num y;
    VAR num z;
    
    ! web params
    VAR num spd := 100;
    VAR num int := 10;
    VAR num lft := -600;
    VAR num rgt := 600;
    VAR num upr := 700;
    VAR num lwr := 100;
    VAR num acc := 100;
    VAR num jrk := 100;
    VAR num dac := 100;
    VAR zonedata zone := fine;
    
    
    
    PROC main()
        SocketCreate udp_socket \UDP;
        SocketBind udp_socket, "192.168.15.81", 1025;
        TPWrite "UDP server ready.";


        !receive   
        WHILE TRUE DO
            SocketReceiveFrom udp_socket \Str := msg, client_ip, client_port;
            
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
                        AccSet acc, jrk \FinePointRamp:=dac;

                        z := upr;

                        WHILE z >= lwr DO
                            IF left_to_right THEN
                                y := lft;
                                MoveL [[300, y, z], [0,1,0,0], [-1,-1,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
                                y := rgt;
                                MoveL [[300, y, z], [0,1,0,0], [-1,-1,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
                            ELSE
                                y := rgt;
                                MoveL [[300, y, z], [0,1,0,0], [-1,-1,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
                                y := lft;
                                MoveL [[300, y, z], [0,1,0,0], [-1,-1,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
                            ENDIF

                            z := z - int;
                            left_to_right := NOT left_to_right;
                        ENDWHILE
                ENDTEST
            ENDIF
            
        ENDWHILE        

        ERROR
            TPWrite "ERRNO: " + ValToStr(ERRNO);
            ! TRYNEXT;

        TPWrite "closing now";
        SocketClose udp_socket;
        
    ENDPROC


    
    
ENDMODULE




MODULE controller
    VAR robtarget current_pos;
    VAR intnum intno2;

    VAR jointtarget jt;

    VAR string print_msg;
    VAR num dist_y;
    VAR num dist_z;
    VAR num spd;
    VAR num cur_error;

    VAR num speed_multiplier := 1500; ! Will reach targets at speed using multiplier, capped by precision rate
    VAR num precision_multiplier := 0.4; ! Max yz speed should be 250 hz * precision multiplier -> mm/s
    VAR bool calibrated;

    ! PERS Params
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num prev_y_target;
    PERS num prev_z_target;

    PERS num y_target;
    PERS num z_target;

    PERS num con_y;
    PERS num con_z;
    PERS num input_spd;

    ! TODO
    ! web/controller speed control? easier to select from options than make custom slider I think?
    ! Prob not to hard to make slider, will just sacrifice precision
    ! DPAD implementation
    ! node that starts docker container
    ! node that checks if controller is connected
    ! single joystick implementation
    ! button on controller also does reset

    ! REAL:
    ! make speed implementation pretty
    ! show position messages
    ! bring back that old button shit
    ! controller connected display
    ! Controller button if goated??

    
    TRAP reset_trap
        StopMove;
        ClearPath;
        StartMove;
        MoveJ [[350, -600, 850], [1,0,0,0], [-1,0,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], v400, fine, tool0 \WObj:=wobj0;
        CustomCalibrate;

        y_target := -600;
        z_target := 850;

        go := FALSE;
        SetDO MyResetSignal, 0;

        ExitCycle;
    ENDTRAP

    PROC CustomCalibrate()
        
        ! Wait for robot to fully stop
        WaitRob \ZeroSpeed;

        jt := CjointT();

        ! Calculate robtarget from jointtarget
        current_pos := CalcRobT(jt, tool0);

        prev_y_target := current_pos.trans.y;
        prev_z_target := current_pos.trans.z;

    ENDPROC
    
    PROC main()

        IDelete intno2;
        CONNECT intno2 WITH reset_trap;
        ISignalDO MyResetSignal, 1, intno2;

        ConfL \Off;

        zone := z100;
        speed := v80;
        AccSet 100, 100 \FinePointRamp:=100;

        CustomCalibrate;

        y_target := prev_y_target;
        z_target := prev_z_target;
        input_spd := 125;

        WHILE TRUE DO

            WaitTime 0.01;

            IF NOT calibrated THEN
                ! Find true y and z
                CustomCalibrate;

                cur_error := Abs(prev_y_target - y_target) + Abs(prev_z_target - z_target);

                IF (cur_error < 0.3) THEN
                    calibrated := TRUE;
                ENDIF
                    
            ENDIF


            WHILE (con_y <> 0) OR (con_z <> 0) DO
                precision_multiplier := input_spd / 250;

                dist_y := precision_multiplier * con_y;
                dist_z := precision_multiplier * con_z;

                y_target := prev_y_target - dist_y;
                z_target := prev_z_target + dist_z;

                ! Enforce Y bounds
                IF y_target > 600 THEN
                    y_target := 600;
                ELSEIF y_target < -600 THEN
                    y_target := -600;
                ENDIF

                ! Enforce Z bounds [250, 850]
                IF z_target > 850 THEN
                    z_target := 850;
                ELSEIF z_target < 250 THEN
                    z_target := 250;
                ENDIF

                spd := speed_multiplier * Sqrt(Pow(con_y, 2) + Pow(con_z, 2));
                speed := [spd, 1000, 5000, 1000];

                MoveL [[350, y_target, z_target], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, z100, tool0;

                prev_y_target := y_target;
                
                prev_z_target := z_target;

                calibrated := FALSE;

            ENDWHILE

        ENDWHILE        
        
    ENDPROC
    
ENDMODULE

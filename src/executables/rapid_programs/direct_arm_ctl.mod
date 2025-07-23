MODULE direct_arm_ctl
    VAR robtarget current_pos;
    VAR intnum intno2;

    VAR num j1;
    VAR num j2;
    VAR num j3;
    VAR num j4;
    VAR num j5;
    VAR num j6;
    VAR jointtarget jt;

    VAR num y;
    VAR num z;
    VAR bool calibrated;
    VAR num cur_error;

    VAR string print_msg;

    VAR num temp1;
    VAR num temp2;

    ! PERS Params
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num prev_y_target;
    PERS num prev_z_target;

    PERS num y_target;
    PERS num z_target;
    
    TRAP reset_trap
        StopMove;
        ClearPath;
        StartMove;
        MoveJ [[350, -600, 850], [1,0,0,0], [-1,0,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], v400, fine, tool0 \WObj:=wobj0;
        CustomCalibrate;

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

        y := current_pos.trans.y;
        z := current_pos.trans.z;

        prev_y_target := y;
        prev_z_target := z;

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

        y_target := y;
        z_target := z;
        calibrated := TRUE;

        WHILE TRUE DO

            WaitTime 0.01;

            if go THEN
                TPWrite("go!");
                ! Enforce Y bounds [-600, 600]
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
                
                go := FALSE;

                ! save location to move to within this task
                temp1 := y_target;
                temp2 := z_target;

                ! Perform movement
                calibrated := FALSE;
                MoveL [[350, y_target, z_target], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, z100, tool0;

                ! save location that was moved to persisent variable
                prev_y_target := temp1;
                prev_z_target := temp2;

            ELSEIF NOT calibrated THEN
                ! Find true y and z
                CustomCalibrate;

                cur_error := Abs(y - y_target) + Abs(z - z_target);

                IF (cur_error > 0.1) THEN
                    TPWrite("movin fine");
                    ! move towards target if there is any error
                    MoveL [[350, y_target, z_target], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], v80, fine, tool0;
                ELSE
                    ! Mark errorless otherwise
                    calibrated := TRUE;
                ENDIF
            ENDIF
        ENDWHILE        
        
    ENDPROC
    
ENDMODULE

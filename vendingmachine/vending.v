//Coffee Vending Machine

`timescale 1 ns / 100 ps
// State definition
`define NORMAL   2'b00
`define BUSY   	 2'b01
`define GIVE_CH  2'b10
`define ERROR    2'b11

module Coffee_Vending_machine(
//Input
	Clock,
	nReset,
	Input_Money,
	Req_Change,
	Click_Black,
	Click_Cream,
	Click_Cream_Sugar,
//Output	
	Money,
	Change,
	Coffee,
	Water,
	Cream,
	Sugar
	)		  ;
	
//Input
input		Clock;
input		nReset;
input 		Input_Money;
input		Req_Change;
input		Click_Black;
input		Click_Cream;
input		Click_Cream_Sugar;

//Output	
output	[4:0]	Money;
output	[4:0]	Change;
output		Coffee;
output		Water;
output		Cream;
output		Sugar;

reg	[4:0]	Money;
reg	[4:0]	Change;
reg		Coffee;
reg		Water;
reg		Cream;
reg		Sugar;
reg	[1:0]	CurrST;
reg	[1:0]	NextST;
wire 		Click;
reg		Busy;
wire		Busy_CH;
wire		Enable_Buy;
reg	[1:0]   Time;
reg [1:0]   Time_Click;

assign Click = Click_Black | Click_Cream | Click_Cream_Sugar;
assign Enable_Buy = (Money[4:0] >= 5'b0010)? 1'b1 : 1'b0; // 2원이상있으면 살수있고 없으면 못산다
assign Enable_CH =  (Money[4:0] != 5'b0000)? 1'b1 : 1'b0; // 0원이아니면 잔돈반환가능 없으면 못한다 
assign Busy_CH = (Change[4:0] != 5'b0001)? 1'b1 : 1'b0;



always@(CurrST or nReset or Input_Money or Req_Change or Click or Busy or Busy_CH or Enable_Buy or Enable_CH or Time)
begin
	case (CurrST)
	  `NORMAL	: begin
	               		if(~nReset)
	                	 begin
	               		     NextST = `NORMAL;
	                	 end
	               	  	else if(Click && Enable_Buy)
	                  	 begin
	                    	     NextST = `BUSY;
	                 	 end
	                 	else if((Req_Change  || Time == 2'b11)&& Enable_CH)
	                 	 begin
	                    	     NextST = `GIVE_CH;
	                 	 end
					
	                 	else
							begin
	                 	  NextST = CurrST;
							  end
	                  end
	   `BUSY	: begin
	   			if(~nReset)
	                	 begin
	               		     NextST = `NORMAL;
	                	 end
	                	else if(~Busy)
	                	 begin
	                	     NextST = `NORMAL;
	                	 end
	                	else 
	                	 NextST = CurrST;
	                  end
	   `GIVE_CH	: begin
	   			if(~nReset)
	                	 begin
	               		     NextST = `NORMAL;
	                	 end
	                	else if(~Busy_CH)
	                	 begin
	                	     NextST = `NORMAL;
	                	 end
	                	else 
	                	 NextST = CurrST;
	                  end
	   default	:begin
	   			NextST = `NORMAL;
	   		 end
	 endcase
end

  always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      CurrST <= `NORMAL;
    else 
     begin
          CurrST <= NextST;
     end
  end 
  
  always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Money  <= 5'b0;
        Change <= 5'b0;
      end
    else if(CurrST == `NORMAL)
      begin
        if(Input_Money && Money != 5'b10000) // 16원 이면 ㄴㄴ
       	 Money  <= Money +5'b1;
       	else if(Click && Enable_Buy)
       	 Money  <= Money -5'b10;
       	else if((Req_Change  || Time == 2'b11)&& Enable_CH) // 잔돈반환가능상태
       	 begin
       	    Change <= Money;      //잔돈몰빵
				 Money  <= 5'b0;			// 돈은 0원
       	 end
      end
    else if(CurrST == `GIVE_CH)
      begin
            Change <= Change -5'b1; // 1원씩 깐다  
      end
  end
  
  always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
	Coffee  <= 1'b0;
	Water   <= 1'b0;
	Cream	<= 1'b0;
	Sugar	<= 1'b0;
      end
    else if(NextST == `NORMAL)
      begin
        Coffee  <= 1'b0;
	Water   <= 1'b0;
	Cream	<= 1'b0;
	Sugar	<= 1'b0;
      end
    else if(NextST == `BUSY && Busy == 1'b0)
      begin
        if(Click_Black)
          begin
            	Coffee  <= 1'b1;
		Water   <= 1'b1;
		Cream	<= 1'b0;
		Sugar	<= 1'b0;
          end
        else if(Click_Cream)
          begin
            	Coffee  <= 1'b1;
		Water   <= 1'b1;
		Cream	<= 1'b1;
		Sugar	<= 1'b0;
          end
        else if(Click_Cream_Sugar)
          begin
            	Coffee  <= 1'b1;
		Water   <= 1'b1;
		Cream	<= 1'b1;
		Sugar	<= 1'b1;
          end
      end
      
  end
  
always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Busy <= 1'b0;
      end
    else if((NextST == `BUSY) &&(CurrST == `NORMAL))
      begin
        Busy <= 1'b1;
      end
    else if(Time_Click == 2'b1)
      begin
        Busy <= 1'b0;
      end
  end 
  

  
always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Time_Click <= 2'b00;
      end
    else if(NextST == `NORMAL)
      begin
        Time_Click <= 2'b00;
      end
    else if((NextST == `BUSY) &&(CurrST == `NORMAL))
      begin
        Time_Click <= 2'b01;
      end
    else if((CurrST == `BUSY) && (Time_Click != 2'b00))
      begin
        Time_Click <= Time_Click - 2'b1;
      end
  end 
  // Time 변수 추가
  
always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Time <= 2'b00;
      end
	else if(Time == 2'b11)
		begin
			Time <= 2'b00;
		end
   else if(CurrST == `NORMAL) // 타임 3클락이면 타임 , 머니, 잔돈 리셋
      begin
			if(Input_Money || Click || Req_Change)
				begin
					Time <= 2'b00;
				end
			else
				begin // 타임 1증가
						Time <= Time + 2'b1;
				end
      end
	else
		begin
			Time <= 2'b00;
		end
  end
 
endmodule

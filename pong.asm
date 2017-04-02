assume cs:code, ss:stack     
; 0,0 lewy gorny rog

data segment
    pkey db "Wcisnij klawisz...$" 
    txt_koniec db "Koniec gry! $" 
      
    xb    dw  36   ; wspolrzedna x  pileczki
    yb    dw  60   ; wspolrzedna y  pileczki 
     
    yp    dw  80  ; wspolrzedna y paletek 
    xp    dw  0  
    
    k     db  2   ; kolor paletki  
    kb    db  3   ; kolor pileczki    
    
    nx    dw  -1   ; kierunek x pilki
    ny    dw  1   ; kierunek y pilki 
    
ends

stack segment
        dw   200  dup(?) 
    top dw   ?
ends

code segment
start:                
    
    ; inicjacja stosu
    mov ax,seg top
    mov ss,ax
    lea sp, top     ; ss:sp -> na wierzcholek stosu    
       
    ; ustawiam rejestry segmentu:
    mov ax, data
    mov ds, ax
    mov es, ax
            
    lea dx, pkey
    mov ah, 9
    int 21h        ; wyjscie string na ds:dx
    
    ; czekaj na klawisz   
    mov ah, 1
    int 21h  
    
    ; tryb graficzny 320x200 px 256 kolorow
    mov al,13h
    mov ah,0
    int 10h 
    
    call koloruj    
    
e1:  
    xor ax,ax
    call sleep	
    jmp pilka  
                   
klawisz: 
    mov ah,01h  ; sprawdza, czy klawisz nacisniety
    int 16h
    jz cisza
    
    mov ah,00h  ; wczytuje znak z klawiatury
    int 16h 
    
    cmp ah,72d
    jne czy_dol 

czy_gora:                 	 ; paletka do gory
    cmp word ptr ds:[yp],0       ; jesli jest na gorze
    je e1			 ; jesli rowne
                 
    call g_przesun
    sub word ptr ds:[yp],2
    jmp e1 
    
czy_dol:    			; paletka do dolu
    cmp ah,80d
    jne cisza			; jesli nie rowne
    
    cmp word ptr ds:[yp],180    ; 180 - bo paletka ma 20px
    je e1
    
    call d_przesun
    add word ptr ds:[yp],2   
    
cisza: 
    jmp e1           
             
    ; kolory np. czerwony 4, zielony 2, jasny niebieski 3
    
koniec:   
    
    mov ax, 4c00h 	; wyjscie do systemu operacyjnego
    int 21h 
    
;--------   
        
punkt proc        
    mov ax,0a000h		; start pamieci video - zaczyna sie od tego adresu
    mov es,ax 
    xor ax,ax
    mov ax,word ptr ds:[yb]
    mov bx,320
    mul bx
    
    mov bx,word ptr ds:[xb]   
    add bx,ax
    mov al,byte ptr ds:[kb]
    mov byte ptr es:[bx],al   
    ret
     
punkt endp

wyczysc proc
    mov ax,0a000h
    mov es,ax  
    xor ax,ax
    mov ax,word ptr ds:[yb]
    mov bx,320
    mul bx
    
    mov bx,word ptr ds:[xb]   
    add bx,ax
    mov al,0
    mov byte ptr es:[bx],al   
    ret
wyczysc endp 
    
;---- ruch pilki -----------------   
    
pilka:  

    call wyczysc
       
    cmp word ptr ds:[xb],0        ; czy pilka na lewej scianie
    jz kolizja
    
    cmp word ptr ds:[xb],320      ; czy pilka na prawej scianie
    jz b_odbicie 
    
    cmp word ptr ds:[xb],2        ; pilka blisko paletki
    jz p_odbicie 
    
    cmp word ptr ds:[yb],2        ; czy pilka na gornej    
    jz mg_odbicie 
    
    cmp word ptr ds:[yb],200      ; czy pilka na dolnej
    jz md_odbicie 
    
    jmp ruch
   
mg_odbicie:
    add word ptr ds:[ny],2        ; zmienia kierunek y na dol
    jmp ruch                 
        
md_odbicie:
    sub word ptr ds:[ny],2        ; zmienia kierunek y na gore
    jmp ruch     
    
b_odbicie:                        ; zmienia kierunek w zaleznosci
    sub word ptr ds:[nx],2
    jmp ruch
    
p_odbicie:  
    xor ax,ax
    mov ax,word ptr ds:[yp]
    cmp word ptr ds:[yb],ax	; czy y pileczki jest nad y paletki
    jb ruch     ; jesli mniejsze, wykonuje ruch (dojdzie do kolizji)
    add ax,20
    cmp word ptr ds:[yb],ax	; czy y pileczki jest pod y+20 paletki
    ja ruch     ; jesli wieksze 

    add word ptr ds:[nx],2    ; odbija od paletki
    
ruch:
    mov ax,word ptr ds:[nx]
    add word ptr ds:[xb],ax  
    
    mov ax,word ptr ds:[ny] 
    add word ptr ds:[yb],ax  
    
    call punkt
    
    jmp klawisz      
    
kolizja: 
    mov al,3    ; tryb tekstowy 80 znakow w linii
    mov ah,0    ; zmiana trybu graficznego
    int 10h

    lea dx,txt_koniec
    mov ah,9
    int 21h 
    
    lea dx,pkey
    mov ah,9
    int 21h        ; output string at ds:dx
    
    ; czeka na klawisz   
    mov ah, 1
    int 21h
   
    jmp koniec   

; --- koniec ruchu pilki    

koloruj:  		; rysuje na ekranie paletke

    mov cx,20    ;
    mov ax,0A000h
    mov es,ax
    
petla_1:             ;   
    xor ax,ax   ;
    mov ax,word ptr ds:[yp] ;
    add ax,cx
    dec cx      ;
    mov bx,320
    mul bx      ; wykona AX*BX = y*320 i zachowa w DX:AX
    
    mov bx,word ptr ds:[xp]    ; AX = 320*y + x 
    add bx,ax 
    mov al,byte ptr ds:[k]
    mov byte ptr es:[bx],al ; zapalenie punktu   
    loop petla_1     
    ret     
    
g_przesun:			; przesuwa paletke do gory
    mov ax,0a000h
    mov es,ax 
    xor ax,ax       
    mov ax,word ptr ds:[yp]
    	; dopisuje jeden znak
    mov bx,320
    mul bx
    
    mov bx,word ptr ds:[xp]
    add bx,ax
    mov al,byte ptr ds:[k]
    mov byte ptr es:[bx],al
    
    	; kasuje jeden znak 
    xor ax,ax  
    mov ax,word ptr ds:[yp]
    add ax,20
    mov bx,320
    mul bx
    
    mov bx,word ptr ds:[xp]   
    add bx,ax
    mov al,0
    mov byte ptr es:[bx],al   
    ret   
    
d_przesun:			; przesuwa paletke na dol
    mov ax,0a000h
    mov es,ax 
    xor ax,ax           
    
    mov ax,word ptr ds:[yp]
    	; dopisuje jeden znak
    add ax,20
    mov bx,320
    mul bx
    
    mov bx,word ptr ds:[xp]
    add bx,ax
    mov al,byte ptr ds:[k]
    mov byte ptr es:[bx],al
    
    	; kasuje jeden znak 
    xor ax,ax  
    mov ax,word ptr ds:[yp]
    mov bx,320
    mul bx
    
    mov bx,word ptr ds:[xp]   
    add bx,ax
    mov al,0
    mov byte ptr es:[bx],al   
    ret
    
sleep: 
    mov cx,0		; usypia na chwile 
    mov dx,7000
    mov ah,86h
    int 15h
    ret              
       
ends  
    
end start

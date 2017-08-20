#Reference: http://www.isi.edu/nsnam/ns/tutorial

if { $argc != 3 } {
        puts "setting default parameters"
        set val(r)    3
        set val(d)                            10
        set val(n)               101
    } else {
        puts "setting custom arguments"
        set val(r) [lindex $argv 0]
        set val(d) [lindex $argv 1]
        set val(n) [lindex $argv 2]
        }

#Project Parameters
set duration 			$val(d)	
set val(intervalVal) 		0.02
set val(packetSizeVal) 		16; #128 bits
set val(repeatTxCopies)    $val(r) 
set val(node_num) 		$val(n)	
set val(dimx)           100	
set val(dimy)           100	



#Node Parameters
set val(chan)           Channel/WirelessChannel    ;#Channel Type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/_randomMAC                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             $val(node_num)                          ;# number of mobilenodes
# routing protocol
# Reference http://www.differencebetween.net/technology/protocols-formats/difference-between-dsr-and-aodv/
set val(rp)              DumbAgent 			;




set ns 					[new Simulator]
set tracefd 			[open randommac.tr w]
$ns trace-all 			$tracefd

set namtrace 			[open random-mac.nam w]
$ns  namtrace-all-wireless $namtrace $val(dimx) $val(dimy)

set topo       			[new Topography]
$topo load_flatgrid     $val(dimx) $val(dimy)

create-god $val(nn)

Mac/_randomMAC set repeatTxCopies_ $val(repeatTxCopies)	
Mac/_randomMAC set intervalTime_ $val(intervalVal)
Mac/_randomMAC set fullduplex_mode_ 0 

#Reference: http://www.isi.edu/nsnam/ns/doc/node46.html
$ns node-config \
                   -adhocRouting $val(rp) \
                   -llType $val(ll) \
                   -macType $val(mac) \
                   -ifqType $val(ifq) \
                   -ifqLen $val(ifqlen) \
                   -antType $val(ant) \
                   -propType $val(prop) \
                   -phyType $val(netif) \
                   -topoInstance $topo \
                   -channel [new $val(chan)] \
                   -agentTrace ON \
                   -routerTrace ON \
                   -macTrace ON \
                   -movementTrace OFF

#Generating the node positions	http://www.cs.unc.edu/~clark/ns/rng/rng.pdf

#Generating random numbers
set randomGen [new RNG]
$randomGen seed 0

set randomX [new RandomVariable/Uniform]
$randomX use-rng $randomGen
#$randomX set min_ [expr -$val(dimx)/2]
$randomX set min_ 0 
#$randomX set max_ [expr $val(dimx)/2]
$randomX set max_ 100 

set randomY [new RandomVariable/Uniform]
$randomY use-rng $randomGen
#$randomY set min_ [expr -$val(dimy)/2]
$randomY set min_ 0 
#$randomY set max_ [expr $val(dimy)/2]
$randomY set max_ 100 

set randomTime [new RandomVariable/Uniform]
$randomTime use-rng $randomGen
$randomTime set min_ 0
$randomTime set max_ $val(intervalVal)


#Creating the sink agent and connecting it to sink node
set sinkNode [$ns node]
$sinkNode random-motion 0
$sinkNode set X_ [expr $val(dimx)/2]
$sinkNode set Y_ [expr $val(dimy)/2]
$sinkNode set Z_ 0
$ns initial_node_pos $sinkNode 5

set null0 [new Agent/Null] 
$ns attach-agent $sinkNode $null0

for {set i 0} {$i <  $val(nn)-1} {incr i} {
	set node($i) [$ns node]
	set random1 [$randomX value]
	set random2 [$randomY value]
	$node($i) set X_ $random1
	$node($i) set Y_ $random2
	$node($i) set Z_ 0
	$ns initial_node_pos $node($i) 1

	set udp($i) [new Agent/UDP]
  $udp($i) set class_ $i
	$ns attach-agent $node($i) $udp($i)

	#Connecting te agents
	$ns connect $udp($i) $null0

	set cbr($i) [new Application/Traffic/CBR]
	$cbr($i) set packetSize_ $val(packetSizeVal)
	$cbr($i) set interval_ $val(intervalVal)
	$cbr($i) attach-agent $udp($i)

	set time1 $randomTime
	$ns at $time1 "$cbr($i) start"
	$ns at $duration "$cbr($i) stop"

}

#$ns initial_node_pos $sinkNode 20

proc finish {} {
        global ns tracefd namtrace
        $ns flush-trace
        close $tracefd
        exec namtrace random-mac.nam &
        exit 0
}


#Connecting the nodes
#$ns duplex-link $n0 $n1 1Mb 10ms DropTail


puts "Starting simulation with random mac"
$ns run


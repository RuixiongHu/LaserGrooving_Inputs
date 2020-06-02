#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstring>
#include <string>
using namespace std;

// after default compiling, input command would be ./a.out LasereCenter.txt
int main (int argc, char* argv[]) {
	

    ofstream outputfile ( argv[1] );
    

    // Specify dt, laser speed and starting porint.
    double deltat=0.0025; // dt of the laser center file
    double x0=14;    // starting point of x coordinate
    double y0=0;       // starting point of y cordinate
    float  speed = 0.1 ; // Laser speed in um/us ( only support x direction movement now) 
    double pulseon = 0.025;   // time (us) of every pulse turned on ; 
    double pulseoff = 4.975;  // time (us) of ecery pulse turned off;
    int lasercycle = 16; // total # of laser cycle is going on;

    vector<float> times;
    double time=0;
    double dt=deltat;

    
    vector<float> xs;
    double dx=deltat*speed;
    double x=x0;
    
    int y=0;
    
    int onoff=0;
    vector<int> onoffs;

    int percent=0;
    
    int ibound = lasercycle * ( (pulseon + pulseoff) / pulseon ) ; 
    int jbound = pulseon / dt ; 
    int test = ( pulseon + pulseoff) / pulseon;

    string space="     ";
   // initialize first row
   outputfile << time << space << x << space  << y << space << percent << "\n" ; 
    
   // loop 
   for ( unsigned int i=0; i< ibound ; i++ ) {
   	for ( unsigned int j=0 ; j < jbound ; j++) {
         if ( i % test == 0 ) {
         	time=time+dt;
         	x=x+dx;
         	percent=1;
         } 


         else {
         
         	if ( i % test == 1 ) {
         		if ( j % test == 0 ) {
         		time=time+dt;
         		x=x+dx;
         		percent=1;
            	}

            	if ( j % test != 0 ) {
         		time=time+dt;
         		x=x+dx;
         		percent=0;
            	}


         	} 	

         	if ( i % test !=1) {
          	time=time+dt;
         	x=x+dx;
         	percent=0;
            }
         }
   	   outputfile << time << space << x << space  << y << space << percent << "\n" ;
   	}
   }

	// for ( unsigned int i=0 ; i<voc.size() ; i++) {
	// 	std::cout << voc[i] << "\n"  ;
	// }

	

	if ( !outputfile.good() ) {
		cerr << " output failes" << endl ; 
	}


	return 0 ;
}

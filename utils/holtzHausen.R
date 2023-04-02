#' Holz Hausen Calculator
#'
#' Method to calculate polygonal bases for circular firewood stacks
#'
#' A holz hausen is a cylindrical stack of firewood. It has an advantage
#' of being largely self-supporting, compact, and minimizes exposure to
#' precipitation while allowing good desicating airflow.
#'
#' Firewood will begin to rot if in direct contact with the ground. It is
#' relatively easy to make linear firewood racks from pressure treated
#' lumber. It's more challenging to create such supports for a circular
#' wood stack.
#'
#' This method allows the user to specify the number of sides in a polyogonal
#' base rack, as well as the length of the outer side, and will calculate
#' the size of boards to cut in order to form segments that fit the desired
#' footprint.
#'
#'           
#'
#'          "Inner" : board composing inside polygon
#' 
#'        ###########        
#'        H         H     "Spacer" (2x): separates inner and outer polygons
#'        H         H
#'     ##################
#' 
#'                   ^--^ "Spacer Offset" : Length of 'overhang'
#'          "Outer" : board composing outside polygon
#'          
#'
#' @param outer Required. How long is each side of the outer polygon,
#'        in inches?
#' 
#' @param sides How many sides will our polygon have? Default 8
#' 
#' @param spacer How long are the spacer boards between the inner and outer
#'        edges? In inches, default 9
#'
#' @param lumberWid How thick are the boards we're using? In inches,
#'     default 1.5, the US standard for "Two-by" boards.
#' 
#' @examples
#'
#' # Calculate dimensions of a 12-sided base with 2 foot outer edges
#'
#' x <- holzHausen(24,sides=12)
#' 
#' #     Number of Sides: 12
#' #          Outer Side: 2'
#' #          Inner Side: 1' 6.4"
#' #       Spacer Length: 9"
#' #       Spacer Offset: 2.8"
#' #       Pile Diameter: 7' 8.7"
#' #      Inner Diameter: 5' 11"
#' #        Lumber Width: 1.5"
#' #     Height per Cord: 2' 9"
#'
#' @return
#' 
#' A named numeric vector, invisibly
#' 
#' Number of Sides     Outer Side   Inner Side   Spacer Length Spacer Offset 
#'           12.00          24.00        18.38            9.00          2.81 
#'   Pile Diameter Inner Diameter Lumber Width Height per Cord 
#'           92.70          71.00         1.50           33.00 


holzHausen <- function(outer, sides=8, spacer=9, lumberWid=1.5 ) {
    ## Return value structure
    rv <- c("Number of Sides"=sides, "Outer Side"=outer)
            
    ## What is the angle we need to calculate the inner edge?
    ang <- 2 * pi / (sides*2) # in radians
    
    ## How far from the outer edge should the spacer be for the inner
    ## side to properly form an internal polygon? We need to account
    ## for the width of the lumber (contributed by the inner edge) in
    ## the tangent calculation
    soff <- signif(tan(ang) * (lumberWid + spacer),3)
    
    ## Then how long is the inner polygon side?
    rv["Inner Side"]  <- outer - (2*soff)
    rv["Spacer Length"] <- spacer
    rv["Spacer Offset"] <- soff
    
    ## What is the diameter of a circle intersecting polygon vertices?
    rv["Pile Diameter"] <- signif(outer / sin(ang), 3)
    ## What about the diameter of the inner polygon?
    rv["Inner Diameter"] <- signif(rv["Inner Side"] / sin(ang), 3)

    rv["Lumber Width"]  <- lumberWid

    ## How tall must the stack be to contain a cord of wood?
    ## A cord is 128 cubic ft, or, so in inches:
    cord <- (12^3) * 128
    rv["Height per Cord"] <- signif(cord / (pi * (rv["Pile Diameter"]/2)^2),2)
    
 
    ## Pretty-print results
    nms <- names(rv)
    txt <- ifelse(nms %in% c("Number of Sides"), rv, in2ft(rv))

    message(paste(sprintf("%20s: %s", nms, txt), collapse="\n"))
    message("")
    invisible(rv)
}

#' Inches-to-feet
#'
#' Converts inches to a compound measure of feet and inches
#'
#' @param inch Required, the length in inches
#'
#' @return A string of format 3' 2.5"
#'
#' @examples
#'
#' in2ft( 26 )

in2ft <- function(inch) {
    ft  <- floor((inch+.5)/12)
    inc <- signif(inch - 12*ft, 2)
    rv  <- ifelse(ft==0, "", paste(ft, "'", sep=""))
    rv2 <- ifelse(inc > 0, paste(rv, " ", inc, '"', sep=""), rv)
    gsub("^ ", "", rv2)
}

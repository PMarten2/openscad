/* 
A project by Chris Wallace to implement the Conway operations on Polyhedra.  
The project is being documented in my blog 
  http://kitwallace.tumblr.com/tagged/conway

Done :
    poly object constructor caching edges
    poly accessors
    primitives T,C,O,D, I , Y(), P(), A()
    
    operators 
       transform(obj,matrix)    matrix transformation of vertices
       kis(obj,ratio, nsides)
       ambo(obj)
       dual(obj)  
       meta(obj,ratio,nsides)
       ortho(obj,ratio,nsides)
       trunc(obj,ratio)
       canon(obj,itr)-  simple canonicalization using reciprocals of centres
       snub(obj,expand)
       expand(obj,expand)
       reflect(obj)
       
    last updated 21 Jan 2015 14:00
 

requires development snapshot
*/
// basic list comprehension functions

function flatten(l) = [ for (a = l) for (b = a) b ] ;
    
function reverse(l) = 
     [for (i=[1:len(l)]) l[len(l)-i]];
   
//  functions for creating the matrices for transforming a single point

function m_translate(v) = [ [1, 0, 0, 0],
                            [0, 1, 0, 0],
                            [0, 0, 1, 0],
                            [v.x, v.y, v.z, 1  ] ];
                            
function m_rotate(v) =  [ [1,  0,         0,        0],
                          [0,  cos(v.x),  sin(v.x), 0],
                          [0, -sin(v.x),  cos(v.x), 0],
                          [0,  0,         0,        1] ]
                      * [ [ cos(v.y), 0,  -sin(v.y), 0],
                          [0,         1,  0,        0],
                          [ sin(v.y), 0,  cos(v.y), 0],
                          [0,         0,  0,        1] ]
                      * [ [ cos(v.z),  sin(v.z), 0, 0],
                          [-sin(v.z),  cos(v.z), 0, 0],
                          [ 0,         0,        1, 0],
                          [ 0,         0,        0, 1] ];
                            
function vec3(v) = [v.x, v.y, v.z];
function transform(v, m)  = vec3([v.x, v.y, v.z, 1] * m);
function transform_points(ps,m) =
   [for (p=ps) transform(p,m)];
       
function m_to(centre,normal) = 
      m_rotate([0, atan2(sqrt(pow(normal.x, 2) + pow(normal.y, 2)), normal.z), 0]) 
    * m_rotate([0, 0, atan2(normal[1], normal[0])]) 
    * m_translate(centre);   
   
function m_from(centre,normal) = 
      m_translate(-centre)
    * m_rotate([0, 0, -atan2(normal[1], normal[0])]) 
    * m_rotate([0, -atan2(sqrt(pow(normal[0], 2) + pow(normal[1], 2)), normal[2]), 0]); 

// modules to orient objects
module orient_to(centre, normal) {   
      translate(centre)
      rotate([0, 0, atan2(normal[1], normal[0])]) //rotation
      rotate([0, atan2(sqrt(pow(normal[0], 2)+pow(normal[1], 2)),normal[2]), 0])
      children();
}

// vector functions

function vadd(points,v,i=0) =
      i < len(points)
        ?  concat([points[i] + v], vadd(points,v,i+1))
        :  [];

function vsum(points,i=0) =  
      i < len(points)
        ?  (points[i] + vsum(points,i+1))
        :  [0,0,0];

function norm2(v) = v.x*v.x+ v.y*v.y + v.z*v.z;

function ssum(list,i=0) =  
      i < len(list)
        ?  (list[i] + ssum(list,i+1))
        :  0;
   
function max(v, max=-9999999999999999,i=0) =
    i < len(v) 
        ?  v[i] > max 
            ?  max(v, v[i], i+1 )
            :  max(v, max, i+1 ) 
        : max;

function min(v, min=9999999999999999,i=0) =
    i < len(v) 
        ?  v[i] < min 
            ?  min(v, v[i], i+1 )
            :  min(v, min, i+1 ) 
        : min;

function contains(val, list, i=0) =  //returns true if list contains val
     i < len(list) 
        ?  val == list[i]
           ?  true
           :  contains(val,list,i+1)
        : false;

function index_of(val,list) =
    search([val],list)[0];
 
function count(val, list) =  // number of occurances of val in list
   ssum([for(v= list) v== val ? 1 :0]);
    
function distinct(list,dlist=[],i=0) =  // return only distinct items of d 
      i==len(list)
         ? dlist
         : contains(list[i],dlist)
             ? distinct(list,dlist,i+1)
             : distinct(list,concat(dlist,list[i]),i+1)
      ;

// points functions

function as_points(indexes,points) =
    [for (i=[0:len(indexes)-1])
          points[indexes[i]]
    ]; 

function centre(points) = 
      vsum(points) / len(points);

function vnorm(points) =
  [for (p=points) norm(p)];
      
function average_norm(points) =
       ssum(vnorm(points)) / len(points);

function transform_points(points, matrix) = 
    [for (p=points) transform(p, matrix) ] ;
   
// vertex functions
    
function vertex_faces(v,faces) =   // return the faces containing v
     [ for (f=faces)  
           if(contains(v,f)) f
     ];
    
function ordered_vertex_faces_r(v,vfaces,cface,ofaces)  =
     len(ofaces) < len(vfaces)
          ? ordered_vertex_faces_r(
              v,
              vfaces,
              face_with_edge(vfaces,reverse(last_face_edge(v,cface))),
              concat(ofaces,[
                 face_with_edge(vfaces,reverse(last_face_edge(v,cface)))]
              )
           )
          : ofaces;  

function ordered_vertex_faces(v,vfaces)  =
    ordered_vertex_faces_r(v,vfaces,vfaces[0],[]);
            
function vertex_edges_r(v,vfaces,cface,vedges)  =
     len(vedges) < len(vfaces)
          ? vertex_edges_r(
              v,
              vfaces,
              face_with_edge(vfaces,reverse(last_face_edge(v,cface))),
              concat(vedges,[distinct_edge(last_face_edge(v,cface))])
              )
          : vedges;

function vertex_edges(v,vfaces)  =
    vertex_edges_r(v,vfaces,vfaces[0],[]);

function ordered_vertex_edges_r(v,vfaces,cface,vedges)  =
     len(vedges) < len(vfaces)
          ? ordered_vertex_edges_r(
              v,
              vfaces,
              face_with_edge(vfaces,reverse(last_face_edge(v,cface))),
              concat(vedges,[last_face_edge(v,cface)])
              )
          : vedges;
 
function ordered_vertex_edges(v,vfaces)  =
    ordered_vertex_edges_r(v,vfaces,vfaces[0],[]);
    
function face_with_edge(faces,edge) =
     flatten(
        [for (f = faces) 
           if (contains(edge,ordered_face_edges(f))) f
        ]);

function face_with_edge_index(faces,edge) =
     flatten(
       [for (i = [0:len(faces)-1]) 
           if (contains(edge,ordered_face_edges(faces[i]))) i
        ]);
          
function last_face_edge(v,face) =   
     flatten(
      [for (e = ordered_face_edges(face))
          if (e[1]==v) e
      ]);  
          
// edge functions
          
function distinct_edge(e) = 
     e[0]< e[1]
           ? e
           : reverse(e);
          
function ordered_face_edges(f) =
 // edges are ordered anticlockwise
    [for (j=[0:len(f)-1])
        [f[j],f[(j+1)%len(f)]]
    ];
 
function distinct_face_edges(f) =
    [for (j=[0:len(f)-1])
       let(p=f[j],q=f[(j+1)%len(f)])
          distinct_edge([p,q])
    ];
    
function distinct_edges(faces) =
   [for (i=[0:len(faces)-1])
       let( f=faces[i])
       for (j=[0:len(f)-1])
       let(p=f[j],q=f[(j+1)%len(f)])
          if(p<q) [p,q]  // no duplicates
   ];
      
function check_euler(obj) =
     //  E = V + F -2    
    len(poly_vertices(obj)) + len(poly_faces(obj)) - 2 ==  len(distinct_edges(obj[2]));
         
function edge_lengths(edges,points) =
 [ for (edge = edges) 
     let(points = as_points(edge,points))
        norm(points[0]-points[1])
 ];

//face functions
 
function normal_r(face) =
     cross(face[1]-face[0],face[2]-face[0]);

function normal(face) =
     - normal_r(face) / norm(normal_r(face));

function triangle(a,b) = norm(cross(a,b))/2;

function face_area(face) =
     ssum([for (i=[0:len(face)-1])
           triangle(face[i], face[(i+1)%len(face)]) ]);

function face_areas(obj) =
   [for (f=poly_faces(obj))
       let(face_points = as_points(f,poly_vertices(obj)))
       let(centre=centre(face_points))
          face_area(vadd(face_points,-centre))
   ];
function face_centre(face,points)  =
   centre(as_points(face,points));
   
function face_centres(obj) =
   [ for (f = poly_faces(obj))
         face_centre(as_points(f,poly_vertices(obj)))
   ];
 
function face_sides(faces) =
    [for (f=faces) len(f)];
        
function face_coplanar(face,tolerance=0.002) =
       norm(cross(cross(face[1]-face[0],face[2]-face[1]),
                  cross(face[2]-face[1],face[3]-face[2])
                 )
           ) < tolerance
       ;
          
function face_analysis_r(faces,edge_counts) =  // get number of occurances of every ngon
   [for (sides=distinct(edge_counts))
        [sides,count(sides,edge_counts)]
   ];

function face_analysis(faces) =
  face_analysis_r(faces,face_sides(faces));
   

// poly functions
//  constructor
function poly(name,vertices,faces) = 
    [name,vertices,faces];
    
// accessors
function poly_name(obj) = obj[0];
function poly_vertices(obj) = obj[1];
function poly_faces(obj) = obj[2];
function poly_edges(obj) = distinct_edges(poly_faces(obj));
    
function poly_non_planar_faces(obj) =
     [for (face = poly_faces(obj))
         if (len(face) >3)
             let (points = as_points(face,poly_vertices(obj)))
              if (!face_coplanar(points)) face
   //              face_coplanar(points)
      ];
             
function poly_normalize(obj,radius) =
   poly(
      name=str(poly_name(obj)," Normalized"),
      vertices=normalize(poly_vertices(obj),radius),
      faces=poly_faces(obj));
    
function poly_spherize(obj,radius=1) =
   poly(
      name=str(poly_name(obj)," Spherized"),
      vertices=spherize(poly_vertices(obj),radius),
      faces= poly_faces(obj));

function poly_transform(obj,matrix) =
   poly(
       name=str(poly_name(obj)," Transformed"),
       vertices=transform_points(poly_vertices(obj),matrix),
       faces=poly_faces(obj));

module show_points(points,r=0.1) {
    for (point=points)
        translate(point) sphere(r);
};

module show_edge(edge, r) {
    p0 = edge[0]; 
    p1 = edge[1];
    v = p1 -p0 ;
      orient_to(p0,v)
         cylinder(r1=r,r2=r, h=norm(v)); 
};

module show_edges(edges,points,r=0.1) {
    for (edge = edges)
        show_edge(as_points(edge, points), r); 
};
        
module poly_render(obj,show_vertices=true,show_edges=true,show_faces=true, rv=0.04, re=0.02) {
     if(show_faces) 
          polyhedron(poly_vertices(obj),poly_faces(obj));
     if(show_vertices) 
         show_points(poly_vertices(obj),rv);
     if(show_edges)
       show_edges(poly_edges(obj),poly_vertices(obj),re);
};

module poly_print(obj) {
    echo(poly_name(obj));
    echo(str(len(poly_vertices(obj)), " Vertices " ,poly_vertices(obj)));
    echo(str(len(poly_faces(obj))," Faces ", poly_faces(obj)));
    echo("face analysis",face_analysis(poly_faces(obj)));
    echo(str(len(poly_edges(obj))," Edges ",poly_edges(obj)));
    echo(str(len(poly_non_planar_faces(obj))," faces are not planar", poly_non_planar_faces(obj)));
};

module poly_describe(obj) {
    echo(poly_name(obj));
    echo(str(len(poly_vertices(obj)), " Vertices " ));
    echo(str(len(poly_faces(obj))," Faces "));
    echo("Analysis ",face_analysis(poly_faces(obj)));
    echo(str(len(poly_edges(obj))," Edges "));
    echo(str(len(poly_non_planar_faces(obj))," faces are not planar"));
};

// primitive solids
C0 = 0.809016994374947424102293417183;
C1 = 1.30901699437494742410229341718;
C2 = 0.7071067811865475244008443621048;
T= poly(name= "T",
       vertices= [[1,1,1],[1,-1,-1],[-1,1,-1],[-1,-1,1]],
       faces= [[2,1,0],[3,2,0],[1,3,0],[2,3,1]]
    );
C = poly(name= "C",
       vertices= [
[ 0.5,  0.5,  0.5],
[ 0.5,  0.5, -0.5],
[ 0.5, -0.5,  0.5],
[ 0.5, -0.5, -0.5],
[-0.5,  0.5,  0.5],
[-0.5,  0.5, -0.5],
[-0.5, -0.5,  0.5],
[-0.5, -0.5, -0.5]],
      faces=
 [
[ 4 , 5, 1, 0],
[ 2 , 6, 4, 0],
[ 1 , 3, 2, 0],
[ 6 , 2, 3, 7],
[ 5 , 4, 6, 7],
[ 3 , 1, 5, 7]]
   );

O = poly(name="O",
         vertices=[
[0.0, 0.0,  C2],
[0.0, 0.0, -C2],
[ C2, 0.0, 0.0],
[-C2, 0.0, 0.0],
[0.0,  C2, 0.0],
[0.0, -C2, 0.0]],
        faces= [
[ 4 , 2, 0],
[ 3 , 4, 0],
[ 5 , 3, 0],
[ 2 , 5, 0],
[ 5 , 2, 1],
[ 3 , 5, 1],
[ 4 , 3, 1],
[ 2 , 4, 1]]   
    );
D = poly(name="D",
         vertices=[
[ 0.0,  0.5,   C1],
[ 0.0,  0.5,  -C1],
[ 0.0, -0.5,   C1],
[ 0.0, -0.5,  -C1],
[  C1,  0.0,  0.5],
[  C1,  0.0, -0.5],
[ -C1,  0.0,  0.5],
[ -C1,  0.0, -0.5],
[ 0.5,   C1,  0.0],
[ 0.5,  -C1,  0.0],
[-0.5,   C1,  0.0],
[-0.5,  -C1,  0.0],
[  C0,   C0,   C0],
[  C0,   C0,  -C0],
[  C0,  -C0,   C0],
[  C0,  -C0,  -C0],
[ -C0,   C0,   C0],
[ -C0,   C0,  -C0],
[ -C0,  -C0,   C0],
[ -C0,  -C0,  -C0]],
         faces=[
[ 12 ,  4, 14,  2,  0],
[ 16 , 10,  8, 12,  0],
[  2 , 18,  6, 16,  0],
[ 17 , 10, 16,  6,  7],
[ 19 ,  3,  1, 17,  7],
[  6 , 18, 11, 19,  7],
[ 15 ,  3, 19, 11,  9],
[ 14 ,  4,  5, 15,  9],
[ 11 , 18,  2, 14,  9],
[  8 , 10, 17,  1, 13],
[  5 ,  4, 12,  8, 13],
[  1 ,  3, 15,  5, 13]]
   );
   
I = poly(name= "I",
         vertices= [
[ 0.5,  0.0,   C0],
[ 0.5,  0.0,  -C0],
[-0.5,  0.0,   C0],
[-0.5,  0.0,  -C0],
[  C0,  0.5,  0.0],
[  C0, -0.5,  0.0],
[ -C0,  0.5,  0.0],
[ -C0, -0.5,  0.0],
[ 0.0,   C0,  0.5],
[ 0.0,   C0, -0.5],
[ 0.0,  -C0,  0.5],
[ 0.0,  -C0, -0.5]],
        faces=[
[ 10 ,  2,  0],
[  5 , 10,  0],
[  4 ,  5,  0],
[  8 ,  4,  0],
[  2 ,  8,  0],
[  6 ,  8,  2],
[  7 ,  6,  2],
[ 10 ,  7,  2],
[ 11 ,  7, 10],
[  5 , 11, 10],
[  1 , 11,  5],
[  4 ,  1,  5],
[  9 ,  1,  4],
[  8 ,  9,  4],
[  6 ,  9,  8],
[  3 ,  9,  6],
[  7 ,  3,  6],
[ 11 ,  3,  7],
[  1 ,  3, 11],
[  9 ,  3,  1]]
);

function Y(n,h=1) =
  poly(name= str("Y",n) ,
      vertices=concat(
        [for (i=[0:n-1])
            [cos(i*360/n),sin(i*360/n),0]
        ],
        [[0,0,h]]
      ),
      faces=concat(
        [for (i=[0:n-1])
            [(i+1)%n,i,n]
        ],
        [[for (i=[0:n-1]) i]]
      )
     );

function P(n,h=1) =
  poly(name=str("P",n) ,
      vertices=concat(
        [for (i=[0:n-1])
            [cos(i*360/n),sin(i*360/n),-h/2]
        ],
        [for (i=[0:n-1])
            [cos(i*360/n),sin(i*360/n),h/2]
        ]
      ),
      faces=concat(
        [for (i=[0:n-1])
            [(i+1)%n,i,i+n,(i+1)%n + n]
        ],
        [[for (i=[0:n-1]) i]], 
        [[for (i=[n-1:-1:0]) i+n]]
      )
     );
        
function A(n,h=1) =
 poly(name=str("A",n) ,
      vertices=concat(
        [for (i=[0:n-1])
            [cos(i*360/n),sin(i*360/n),-h/2]
        ],
        [for (i=[0:n-1])
            [cos((i+1/2)*360/n),sin((i+1/2)*360/n),h/2]
        ]
      ),
      faces=concat(
        [for (i=[0:n-1])
            [(i+1)%n,i,i+n]
        ],
        [for (i=[0:n-1])
            [(i+1)%n,i+n,(i+1)%n + n]
        ],
        
        [[for (i=[0:n-1]) i]], 
        [[for (i=[n-1:-1:0]) i+n]]
      )
     );
// canonicalisation
   
// normalize the points to have origin at 0,0,0 
function centre_points(points) = 
     vadd(points, - centre(points));

//scale to average radius = radius
function normalize(points,radius) =
    points * radius /average_norm(points);

function spherize(points,radius) =
    [for (p=points)
        p * radius /norm(p)];
      
function rdual(obj,radius=1) =
      poly(name=str("c",poly_name(obj)),
           vertices =
                [ for (f=poly_faces(obj))
                  let (c=centre(
                         as_points(f,
                           normalize(centre_points(poly_vertices(obj)),radius))))
                     c / norm2(c)
                ]
           ,
           faces= 
            [for (vi = [0:len(poly_vertices(obj))-1])    // each old vertex creates a new face, with 
           let (vf=vertex_faces(vi,poly_faces(obj)))   // vertex faces in left-hand order 
           [for (of = ordered_vertex_faces(vi,vf))
              index_of(of,poly_faces(obj))               
           ]
          ]
           );
          
function canon(obj,n=1) = 
    n > 0 
       ? canon(rdual(rdual(obj)),n-1)   
       : obj;
           
           
// Conway operators 
function kis(obj,expand=-0.1, fn=[]) =
    poly(name=str("k",poly_name(obj)),
      vertices= 
         concat(poly_vertices(obj),                   // original vertices
         [for (f = poly_faces(obj))               // new centrid vertices
            let(fp=as_points(f,poly_vertices(obj)))
            (len(fn)==0 || contains(len(f),fn))   // to be included
               ? centre(fp) + normal(fp)*expand    // centroid + a bit of normal
               : []                               // to preserve the numbering for faces
         ]),
      faces=
        flatten(
         [for (i = [0:len(poly_faces(obj))-1])   // use indexes so new vertices can be located
            let(f = poly_faces(obj)[i])
            (len(fn)==0 || contains(len(f),fn))
              ? [for (p=[0:len(f)-1])            //replace face with trianges
                [f[p],f[(p+1)%len(f)],len(poly_vertices(obj))+i]
               ]
              : [f]                              // original face
         ]) 
    );

function gyro(obj,twist=0.7,expand=0.2) =
/*
  not yet working - can use ds 
  this needs changing so that each face includes the twisted vertex form its neighbouring face,
  making a pentagon - initially two sides with be colinear but adjustment will change the shape
  need to find the new vertex to add to the following code
*/
              
    poly(name=str("g",poly_name(obj)),
      vertices= 
        concat(
           poly_vertices(obj),    
           [for (f = poly_faces(obj))
              let (fp= as_points(f,poly_vertices(obj)))
              centre(fp) + normal(fp)*expand] ,  
           flatten(
              [for (f = poly_faces(obj))                 
                [for (e = ordered_face_edges(f))
                   let (ep = as_points(e,poly_vertices(obj)))
                      ep[0]+ twist*(ep[1]-ep[0]) 
              ]         
           ])
        ),     

      faces=   // only if all faces the same size 
        flatten(
         [for (i = [0:len(poly_faces(obj))-1])   
             let(f = poly_faces(obj)[i])
             [for (j=[0:len(f)-1])            
                [f[j],     // original vertex
                 len(poly_vertices(obj))+len(poly_faces(obj))+i*len(f)+(j+len(f)-1)%len(f),  
                 len(poly_vertices(obj))+i,
                 len(poly_vertices(obj))+len(poly_faces(obj))+i*len(f)+j
                ]
            ]    
         ]) 
    );
              
function meta(obj,expand=0.1, fn=[]) =
    let(pe=poly_edges(obj))
    poly(name=str("m",poly_name(obj)),
      vertices= 
         concat(poly_vertices(obj),                   // original vertices
         [for (f = poly_faces(obj))               // new centre vertices
            let(fp=as_points(f,poly_vertices(obj)))
            (len(fn)==0 || contains(len(f),fn))   // to be included
               ? centre(fp) + normal(fp)*expand    // centroid + a bit of normal
               : []                               // to preserve the numbering for faces
         ],
         [for (e=pe)
             let (ep = as_points(e,poly_vertices(obj)))
           (ep[0]+ep[1])/2
         ]),
      faces=
        flatten(
         [for (i = [0:len(poly_faces(obj))-1])   // use indexes so new vertices can be located
            let(f = poly_faces(obj)[i])
            (len(fn)==0 || contains(len(f),fn))
              ? flatten(
                 [for (p=[0:len(f)-1])            //  replace face with 2n trianges          
                   [
                     [
                       len(poly_vertices(obj))
                         + len(poly_faces(obj))
                         + index_of(distinct_edge([f[p],f[(p+1)%len(f)]]),pe),
                       len(poly_vertices(obj))+i,
                       f[p]
                     ]
                    ,           
                  [f[(p+1)%len(f)],
                   len(poly_vertices(obj))+i,
                   len(poly_vertices(obj))
                     + len(poly_faces(obj)) 
                     + index_of(distinct_edge([f[p],f[(p+1)%len(f)]]),pe)
                  ]         
                 ]
                ]
                 )
              : [f]                              // original face
         ]) 
    ); 

function pyra(obj,expand=0.1, fn=[]) =   // very like meta but different triangles
    let(pe=poly_edges(obj))
    poly(name=str("p",poly_name(obj)),
      vertices= 
         concat(poly_vertices(obj),               // original vertices
         [for (f = poly_faces(obj))               // new centre vertices
            let(fp=as_points(f,poly_vertices(obj)))
            (len(fn)==0 || contains(len(f),fn))   // to be included
               ? centre(fp) + normal(fp)*expand    // centroid + a bit of normal
               : []                               // to preserve the numbering for faces
         ]
         ,
         [for (e=pe)
          let (ep = as_points(e,poly_vertices(obj)))
             (ep[0]+ep[1])/2
         ]
         ),
      faces=
        flatten(
         [ for (i = [0:len(poly_faces(obj))-1])   // use indexes so new vertices can be located
            let(f = poly_faces(obj)[i])
            (len(fn)==0 || contains(len(f),fn))
              ? flatten(
                 [for (p=[0:len(f)-1])            //  replace face with 2n trianges  
                   let(va= len(poly_vertices(obj))
                         + len(poly_faces(obj))
                         + index_of(distinct_edge([f[p],f[(p+1)%len(f)]]),pe))
                   let(vb= len(poly_vertices(obj))
                         + len(poly_faces(obj))
                         + index_of(distinct_edge([f[(p-1+len(f))%len(f)],f[p]]),pe))
                 
                   [
                     [va,f[p],vb]
                    ,           
                     [len(poly_vertices(obj))+i,va,vb] 
                   ]         
                 ]
                )
              : [f]                              // original face
         ] ) 
    ); 
function ortho(obj,expand=0.1, fn=[]) =   // very like meta but divided into quadriterals
     let(pe=poly_edges(obj))
     poly(name=str("0",poly_name(obj)),
      vertices= 
         concat(poly_vertices(obj),               // original vertices
         [for (f = poly_faces(obj))               // new centre vertices
            let(fp=as_points(f,poly_vertices(obj)))
            (len(fn)==0 || contains(len(f),fn))   // to be included
               ? centre(fp) + normal(fp)*expand   // centroid + a bit of normal
               : []                               // to preserve the numbering for faces
         ],
         [for (e=pe)
             let (ep = as_points(e,poly_vertices(obj)))
           (ep[0]+ep[1])/2
         ]),
      faces=
        flatten(
         [ for (i = [0:len(poly_faces(obj))-1])   // use indexes so new vertices can be located
            let(f = poly_faces(obj)[i])
            (len(fn)==0 || contains(len(f),fn))
              ? 
                 [for (p=[0:len(f)-1])            //  replace face with 2n quadrilaterals  
                   let(va= len(poly_vertices(obj))
                         + len(poly_faces(obj))
                         + index_of(distinct_edge([f[p],f[(p+1)%len(f)]]),pe))
                   let(vb= len(poly_vertices(obj))
                         + len(poly_faces(obj))
                         + index_of(distinct_edge([f[(p-1+len(f))%len(f)],f[p]]),pe))
                   let(vc = len(poly_vertices(obj))+i)
                     [va,f[p],vb,vc]                    
                 ]
              : [f]                              // original face
         ] ) 
    ); 

function trunc(obj,ratio=0.25, fn=[]) = 
  ratio >= 0.5
    ? ambo(obj,fn)
    : 
       let(pe=poly_edges(obj))
       poly(name=str("t",poly_name(obj)),
      vertices=         
         flatten(
            [for (e=pe)
             let (ep = as_points(e,poly_vertices(obj)))
               [
                 ep[0]+ratio*(ep[1]-ep[0]),
                 ep[1]+ratio*(ep[0]-ep[1])         
               ]
           ])
         ,
      faces= 
         concat(    
            [for (face = poly_faces(obj))
            let (edges = ordered_face_edges(face))
            flatten([for (i =[0:len(edges)-1] )         
                let (ei = edges[i])
                let (k= index_of(distinct_edge(ei),pe))
                let (oei=poly_edges(obj)[k])           
                   [  ei==oei ? 2 *k: 2*k+1 ,
                      ei==oei ? 2 *k+1: 2*k 
                   ]          
            ])
         ] 
     ,       
    [for (vi = [0:len(poly_vertices(obj))-1])    // each old vertex creates a new face, with 
         let (vf=vertex_faces(vi,poly_faces(obj))) // the old edges in left-hand order as vertices
         [for (ve = ordered_vertex_edges(vi,vf))                 
              let (k=index_of(distinct_edge(ve),pe))
              let (ue = poly_edges(obj)[k])
                 ve == ue 
                    ? 2 *k +1
                    : 2 * k                            
           ]
          ]  
         )
    ); 
         
function ambo(obj) =
      let(pe=poly_edges(obj))
      poly(name=str("a",poly_name(obj)),
       vertices= [for (e = poly_edges(obj))                 
           let (ep = as_points(e,poly_vertices(obj)))
           (ep[0]+ep[1])/2             // vertices are the edge midpoints
                                       // so the new vertex order is the old edge order
                ],     
       faces= 
         concat(
         [for (face = poly_faces(obj))
            [for (e = distinct_face_edges(face))          // old faces become the same with the new vertices
              index_of(e,pe)
            ]
         ]     
       ,        
        [for (vi = [0:len(poly_vertices(obj))-1])    // each old vertex creates a new face, with 
           let (vf=vertex_faces(vi,poly_faces(obj))) // the old edges in left-hand order as vertices
           [for (ve = vertex_edges(vi,vf))
              index_of(ve,pe)               
           ]
          ]  
         )
       );

function dual(obj) =
      poly(name=str("d",poly_name(obj)),
           vertices = 
              [for (f = poly_faces(obj))
                face_centre(f,poly_vertices(obj))   
              ],
           faces= 
          [for (vi = [0:len(poly_vertices(obj))-1])    // each old vertex creates a new face, with 
           let (vf=vertex_faces(vi,poly_faces(obj)))   // vertex faces in left-hand order 
           [for (of = ordered_vertex_faces(vi,vf))
              index_of(of,poly_faces(obj))               
           ]
          ] 
           );

function expand_faces(faces,start=0,i=0) = 
      i < len(faces)
           ? concat(
               [[for (i=[0:len(faces[i])-1])  i + start]],
                  expand_faces(faces,start+len(faces[i]),i+1)
               )
           :[]; 

function new_vertex(obj,vi,of)=
       expand_faces(poly_faces(obj))[index_of(of,poly_faces(obj))][index_of(vi,of)]  ;    
       
function snub(obj,expand=0.5) =             
   poly(name=str("s",poly_name(obj)),
       vertices= 
          flatten([for (f = poly_faces(obj))   
            let (r = -90 / len(f))
            let (fp = as_points(f,poly_vertices(obj)))
            let (c = centre(fp))
            let (n = normal(fp))
            let (m =  m_from(c,n) * m_rotate([0,0,r]) * m_translate([0,0,expand]) * m_to(c,n))
               [for (p = fp) transform(p,m)]
            ]),     
       faces = 
          concat(expand_faces(poly_faces(obj)) ,
          ,   // vertex faces 
                 [for (vi=[0:len(poly_vertices(obj))-1])   
                  let (vf=vertex_faces(vi,poly_faces(obj)))   // vertex faces in left-hand order 
                  [for (of = ordered_vertex_faces(vi,vf))
                     new_vertex(obj,vi,of)
                  ]
                 ],
             flatten( [for (face=poly_faces(obj))
                flatten(  [for (edge=ordered_face_edges(face))
                   let (oppface=face_with_edge(poly_faces(obj),reverse(edge)))
                   let (e00=new_vertex(obj,edge[0],face))
                   let (e01=new_vertex(obj,edge[1],face))                 
                   let (e10=new_vertex(obj,edge[0],oppface))                 
                   let (e11=new_vertex(obj,edge[1],oppface)) 
                   if (edge[0]<edge[1])
                      [
                         [e00,e10,e11],
                         [e01,e00,e11]
                      ] 
                   ])
                ])     
          )
       ); 

function expand(obj,expand=0.5) =  
   poly(name=str("s",poly_name(obj)),
       vertices= 
          flatten([for (f = poly_faces(obj))   
            let (fp = as_points(f,poly_vertices(obj)))
            let (c = centre(fp))
            let (n = normal(fp))
            let (m =  m_from(c,n) *  m_translate([0,0,expand]) * m_to(c,n))
               [for (p = fp) transform(p,m)]
            ]),     
       faces = 
             concat(
                 expand_faces(poly_faces(obj))  // new expanded faces
               ,   // vertex faces 
                 [for (vi=[0:len(poly_vertices(obj))-1])   
                  let (vf=vertex_faces(vi,poly_faces(obj)))   // vertex faces in left-hand order 
                  [for (of = ordered_vertex_faces(vi,vf))
                     new_vertex(obj,vi,of)
                  ]
                 ]
              ,    //edge faces 
               flatten([for (face=poly_faces(obj))
                  [for (edge=ordered_face_edges(face))
                   let (oppface=face_with_edge(poly_faces(obj),reverse(edge)))
                   let (e00=new_vertex(obj,edge[0],face))
                   let (e01=new_vertex(obj,edge[1],face))                 
                   let (e10=new_vertex(obj,edge[0],oppface))                 
                   let (e11=new_vertex(obj,edge[1],oppface)) 
                   if (edge[0]<edge[1])
                        [e00,e10,e11,e01]                 
                   ]
                ] )             
              )
       ); 
                   
function reflect(obj) =
    poly(name=str("r",poly_name(obj)),
         vertices =
          [for (v = poly_vertices(obj))
              [v.x,-v.y,v.z]
          ],
        faces=  // reverse the winding order 
          [ for (face =poly_faces(obj))
              reverse(face)
          ]
    );
         
// measures 
module ruler(n) {
   for (i=[0:n-1]) 
       translate([(i-n/2 +0.5)* 10,0,0]) cube([9.8,5,2], center=true);
}

module ground(x=0) {
   translate([0,0,-(100+x)]) cube(200,center=true);
}
     
$fn=20;
s=canon(ortho(C,0.5),1);
poly_print(s);
scale(10) poly_render(s,true,true,false,0.04,0.04);
//ruler(10);

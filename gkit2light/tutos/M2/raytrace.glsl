
#version 330

#ifdef VERTEX_SHADER
out vec2 position;

void main(void)
{
    vec3 positions[3]= vec3[3]( vec3(-1, 1, -1), vec3( -1, -3, -1), vec3( 3,  1, -1) );
    
    gl_Position= vec4(positions[gl_VertexID], 1.0);
    position= positions[gl_VertexID].xy;
}
#endif


#ifdef FRAGMENT_SHADER

struct Triangle
{
	vec3 a;	// sommet
	vec3 ab;	// arete 1
	vec3 ac;	// arete 2
};

// uniform buffer 0
uniform triangleData
{
	Triangle triangles[1024];
};

vec3 normal( const float hitu, const float hitv, const Triangle triangle )
{
    return normalize( (1 - hitu - hitv) * (triangle.ab + triangle.ac) + hitu * triangle.ab + hitv * triangle.ac) ;
}

bool intersect( const Triangle triangle, const vec3 o, const vec3 d, const float tmax, out float rt, out float ru, out float rv )
{
        vec3 pvec= cross(d, triangle.ac);
        float det= dot(triangle.ab, pvec);
        float inv_det= 1.0f / det;

	vec3 tvec= o - triangle.a; 
        float u= dot(tvec, pvec) * inv_det;
        vec3 qvec= cross(tvec, triangle.ab);
        float v= dot(d, qvec) * inv_det;

        /* calculate t, ray intersects triangle */
        rt= dot(triangle.ac, qvec) * inv_det;
        ru= u;
        rv= v;

        // ne renvoie vrai que si l'intersection est valide : 
	// interieur du triangle, 0 < u < 1, 0 < v < 1, 0 < u+v < 1
	if(any(greaterThan(vec3(u, v, u+v), vec3(1, 1, 1))) || any(lessThan(vec2(u, v), vec2(0, 0))))
		return false;
	// comprise entre 0 et tmax du rayon
        return (rt < tmax && rt > 0);
}

uniform mat4 mvpInvMatrix;
uniform int triangle_count;

in vec2 position;
out vec4 fragment_color;


void main( )
{
	// construction du rayon pour le pixel, passage depuis le repere projectif
	vec4 oh= mvpInvMatrix * vec4(position, 0, 1);       // origine sur near
	vec4 eh= mvpInvMatrix * vec4(position, 1, 1);       // extremite sur far

	// origine et direction
	vec3 o= oh.xyz / oh.w;                              // origine
	vec3 d= eh.xyz / eh.w - oh.xyz / oh.w;              // direction

	float hit= 1;	// tmax = far, une intersection valide est plus proche que l'extremite du rayon / far...
	float hitu= 0;
	float hitv= 0;
	int hitid= 0;

	for(int i= 0; i < triangle_count; i++)
	{
		float t, u, v;
		if(intersect(triangles[i], o, d, hit, t, u, v))
		{
			hit= t;
			hitu= u;
			hitv= v;
			hitid= i;
		}
	}

	vec3 normal = normal(hitu, hitv, triangles[hitid]);
	vec3 light = vec3(1.0);
	vec3 diffuse = light*max(0.0 ,dot( normalize(normal), normalize (  -d )));		
	
	fragment_color= vec4(diffuse, 1);
}
#endif

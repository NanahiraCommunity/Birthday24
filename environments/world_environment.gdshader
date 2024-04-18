shader_type sky;
render_mode use_half_res_pass;

uniform vec3 skyDayColor : source_color;
uniform vec3 horizonDayColor : source_color;
uniform vec3 skyNightColor : source_color;
uniform vec3 horizonNightColor : source_color;
uniform vec3 topSunRiseSet : source_color;
uniform vec3 horizonSunRiseSet : source_color;

void sky() {
	float col = clamp(EYEDIR.y / 0.05, 0.0, 1.0);
	vec3 skyColorDay = mix(horizonDayColor, skyDayColor, col);
	vec3 skyColorNight = mix(horizonNightColor, skyNightColor, col);
	vec3 skyColorSunRiseSet = mix(horizonSunRiseSet, topSunRiseSet, col);
	vec3 skyColor = vec3(0.0, 0.0, 0.0);
	
	if (LIGHT0_DIRECTION.y > 0.0) {
		if (LIGHT0_DIRECTION.y > 0.1) {
			skyColor = skyColorDay;
		} else {
			skyColor = mix(skyColorSunRiseSet, skyColorDay, LIGHT0_DIRECTION.y);
		}
	} else {
		if (LIGHT0_DIRECTION.y > -0.3) {
			skyColor = mix(skyColorSunRiseSet, skyColorNight, abs(LIGHT0_DIRECTION.y));
		}
		skyColor = skyColorNight;
	}
	
	COLOR = skyColor;
	
	//vec3 finalColor = mix(horizonColor, skyColor, col);
	//COLOR = finalColor * LIGHT0_ENERGY;
}

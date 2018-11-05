({
	myAction : function(component, event, helper) {
		
	},
	doInit : function(component) {
    	component.set("v.slides", [
            'https://s3-us-west-1.amazonaws.com/sfdc-demo/houses/living_room.jpg',
            'https://s3-us-west-1.amazonaws.com/sfdc-demo/houses/eatinkitchen.jpg',
			'https://s3-us-west-1.amazonaws.com/sfdc-demo/houses/kitchen.jpg',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img8?isdtp=p1',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img7?isdtp=p1',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img6?isdtp=p1',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img5?isdtp=p1',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img4?isdtp=p1',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img3?isdtp=p1',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img2?isdtp=p1',
            'https://geng-dev-ed--c.ap5.visual.force.com/resource/1511029650000/img1?isdtp=p1',
        ]);
    },
	doRegistInit : function(component) {
        component.set("v.registInit", true);
	},

	closeRegistInit : function(component) {
        component.set("v.registInit", false);
	}
})
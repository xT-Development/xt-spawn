return {
    useContext = false, -- Use ox_lib context rather than menu

    spawns = {
        {
            label = 'Legion Square',
            icon = 'fas fa-building',
            groups = false,
            coords = vector4(196.61, -943.22, 30.69, 306.86),
            -- iconAnimation = 'fade'
            -- iconColor = 'green'
        },

        {
            label = 'Sandy Shores',
            icon = 'fas fa-caravan',
            groups = false,
            coords = vector4(1626.99, 3559.97, 35.26, 302.52)
        },

        {
            label = 'Paleto Bay',
            icon = 'fas fa-umbrella-beach',
            groups = false,
            coords = vector4(135.34, 6380.65, 31.35, 49.25)
        },

        {
            label = 'MRPD',
            icon = 'fas fa-certificate',
            iconColor = 'blue',
            description = 'Spawn @ MRPD - Police Only',
            groups = { 'police', 'lspd' },
            coords = vector4(473.31, -1019.65, 28.1, 232.58)
        },

        {
            label = 'Pillbox',
            icon = 'fas fa-star-of-life',
            iconColor = 'red',
            description = 'Spawn @ Pillbox - EMS Only',
            groups = { 'ambulance', 'ems' },
            coords = vector4(292.93, -613.05, 43.4, 49.94)
        },
    }
}
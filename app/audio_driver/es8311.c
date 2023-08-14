
#include "luat_base.h"
#include "luat_gpio.h"
#include "luat_i2c.h"
#include "luat_audio_air101.h"

#include "es8311.h"

#define LUAT_LOG_TAG "es8311"
#include "luat_log.h"

static void es8311_write_reg(uint8_t addr, uint8_t data){
    uint8_t temp[] = {addr,data};
    luat_i2c_send(0, ES8311_ADDR, temp, 2 , 1);
	luat_timer_mdelay(1);
}

static uint8_t es8311_read_reg(uint8_t addr){
	uint8_t temp=0;
    luat_i2c_send(0, ES8311_ADDR, &addr, 1 , 0);
    luat_i2c_recv(0, ES8311_ADDR, &temp, 1);
	return temp;
}

static int es8311_codec_standby(void){
    es8311_write_reg(ES8311_DAC_REG32, 0x00);
    es8311_write_reg(ES8311_ADC_REG17, 0x00);
    es8311_write_reg(ES8311_SYSTEM_REG0E, 0xFF);
    es8311_write_reg(ES8311_SYSTEM_REG12, 0x02);
    es8311_write_reg(ES8311_SYSTEM_REG14, 0x00);
    es8311_write_reg(ES8311_SYSTEM_REG0D, 0xFA);
    es8311_write_reg(ES8311_RESET_REG00, 0x00);
    es8311_write_reg(ES8311_RESET_REG00, 0x1F);
    es8311_write_reg(ES8311_CLK_MANAGER_REG01, 0x30);
    es8311_write_reg(ES8311_CLK_MANAGER_REG01, 0x00);
    es8311_write_reg(ES8311_GP_REG45, 0x01);
    es8311_write_reg(ES8311_SYSTEM_REG0D, 0xFC);
    return 0;
}

static uint8_t es8311_codec_vol(uint8_t vol){
    if(vol < 0 || vol > 100){
		return -1;
    }
    int gain = vol == 0 ? -955 : (vol - 80) * 5;
	uint8_t reg_val = (uint8_t)((gain + 955) / 5);
	es8311_write_reg(ES8311_DAC_REG32, reg_val);
	return vol;
}

/*0---master, 1---slave*/
static void es8311_codec_mode(uint8_t mode){
	if (mode == 0){
		es8311_write_reg(ES8311_RESET_REG00, 0xC0);
	}else{	
		es8311_write_reg(ES8311_RESET_REG00, 0x80);
	}
}

static int es8311_codec_samplerate(uint16_t samplerate){
    if(samplerate != 8000 && samplerate != 16000 && samplerate != 32000 &&
        samplerate != 11025 && samplerate != 22050 && samplerate != 44100 &&
        samplerate != 12000 && samplerate != 24000 && samplerate != 48000)
    {
        LLOGE("samplerate error!\n");
        return -1;
    }
    // uint8_t i = 0;
	static int mclk = 0;
	static int switchflag = 0;
    switch(samplerate){
        case 8000:
			if (mclk == 0){
				mclk = 1;
			}
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, 0x08);
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x44);
			if (switchflag == 0){
				switchflag = 1;
	            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x19);
	            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x19);
			}
            break;
        case 16000:
			if (mclk == 0){
				mclk = 1;
			}
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, 0x90);
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
			if (switchflag == 0){
				switchflag = 1;
	            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x19);
	            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x19);
			}
            break;
        case 32000:
			if (mclk == 0){
				mclk = 1;
			}
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, 0x18);
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x44);
			if (switchflag == 0){
				switchflag = 1;
	            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x19);
	            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x19);
			}
            break;
        case 44100:
			mclk = 0;
			switchflag = 0;
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, (0x03 << 3));
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x10);
            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x10);
            break;
        case 22050:
			mclk = 0;
			switchflag = 0;
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, (0x02 << 3));
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x10);
            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x10);
            break;
        case 11025:
			mclk = 0;			
			switchflag = 0;
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, (0x01 << 3));
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x10);
            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x10);
            break;
        case 48000:
			mclk = 0;		
			switchflag = 0;
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, (0x03 << 3));
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x10);
            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x10);
            break;
        case 24000:
			mclk = 0;		
			switchflag = 0;
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, (0x02 << 3));
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x10);
            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x10);
            break;
        case 12000:
			mclk = 0;			
			switchflag = 0;
            es8311_write_reg(ES8311_CLK_MANAGER_REG02, (0x01 << 3));
            es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
            es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x10);
            es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x10);
            break;
        default:
            break;
    }
    return 0;
}

static int es8311_update_bits(uint8_t reg, uint8_t mask, uint8_t val){
    uint8_t old, new;
    old = es8311_read_reg(reg);
    new = (old & ~mask) | (val & mask);
    es8311_write_reg(reg, new);
    return 0;
}

static int es8311_codec_samplebits(uint8_t samplebits){
    if(samplebits != 8 && samplebits != 16 && samplebits != 24 && samplebits != 32){
        LLOGE("bit_width error!\n");
        return -1;
    }
    int wl;
    switch (samplebits)
    {
    case 16:
        wl = 3;
        break;
    case 18:
        wl = 2;
        break;
    case 20:
        wl = 1;
        break;
    case 24:
        wl = 0;
        break;
    case 32:
        wl = 4;
        break;
    default:
        return -1;
    }
    es8311_update_bits(ES8311_SDPIN_REG09,
                        ES8311_SDPIN_REG09_DACWL_MASK,
                        wl << ES8311_SDPIN_REG09_DACWL_SHIFT);
    es8311_update_bits(ES8311_SDPOUT_REG0A,
                        ES8311_SDPOUT_REG0A_ADCWL_MASK,
                        wl << ES8311_SDPOUT_REG0A_ADCWL_SHIFT);
    return 0;
}

static int es8311_codec_channels(uint8_t channels){
    return 0;
}

static int es8311_reg_init(void){
    /* reset codec */
    es8311_write_reg(ES8311_RESET_REG00, 0x1F);
    es8311_write_reg(ES8311_GP_REG45, 0x00);

    luat_timer_mdelay(10);

    // es8311_write_reg(ES8311_GPIO_REG44, 0x08);
    // luat_timer_mdelay(1);
    // es8311_write_reg(ES8311_GPIO_REG44, 0x08);

    /* set ADC/DAC CLK */
    /* MCLK from BCLK  */
    es8311_write_reg(ES8311_CLK_MANAGER_REG01, 0x30);
    es8311_write_reg(ES8311_CLK_MANAGER_REG02, 0x90);
    es8311_write_reg(ES8311_CLK_MANAGER_REG03, 0x19);
    es8311_write_reg(ES8311_ADC_REG16, 0x02);// bit5:0~non standard audio clock
    es8311_write_reg(ES8311_CLK_MANAGER_REG04, 0x19);
    es8311_write_reg(ES8311_CLK_MANAGER_REG05, 0x00);
	/*new cfg*/
	es8311_write_reg(ES8311_CLK_MANAGER_REG06, BCLK_DIV);
	es8311_write_reg(ES8311_CLK_MANAGER_REG07, 0x01);
	es8311_write_reg(ES8311_CLK_MANAGER_REG08, 0xff);
    /* set system power up */
    es8311_write_reg(ES8311_SYSTEM_REG0B, 0x00);
    es8311_write_reg(ES8311_SYSTEM_REG0C, 0x00);
    es8311_write_reg(ES8311_SYSTEM_REG10, 0x1F);
    es8311_write_reg(ES8311_SYSTEM_REG11, 0x7F);
    /* chip powerup. slave mode */
    es8311_write_reg(ES8311_RESET_REG00, 0x80);
    luat_timer_mdelay(50);

    /* power up analog */
    es8311_write_reg(ES8311_SYSTEM_REG0D, 0x01);
    /* power up digital */
    es8311_write_reg(ES8311_CLK_MANAGER_REG01, 0x3F);
    // SET ADC
    es8311_write_reg(ES8311_SYSTEM_REG14, DADC_GAIN);
    // SET DAC
    es8311_write_reg(ES8311_SYSTEM_REG12, 0x00);
    // ENABLE HP DRIVE
    es8311_write_reg(ES8311_SYSTEM_REG13, 0x10);
    // SET ADC/DAC DATA FORMAT
    es8311_write_reg(ES8311_SDPIN_REG09, 0x0c);
    es8311_write_reg(ES8311_SDPOUT_REG0A, 0x0c);

    /* set normal power mode */
    es8311_write_reg(ES8311_SYSTEM_REG0E, 0x02);
    es8311_write_reg(ES8311_SYSTEM_REG0F, 0x44);
    // SET ADC
    /* set adc softramp */
    es8311_write_reg(ES8311_ADC_REG15, 0x00);
    /* set adc hpf */
    es8311_write_reg(ES8311_ADC_REG1B, 0x05);
    /* set adc hpf,ADC_EQ bypass */
    es8311_write_reg(ES8311_ADC_REG1C, 0x65);
    /* set adc digtal vol */
    es8311_write_reg(ES8311_ADC_REG17, ADC_VOLUME_GAIN);

    /* set dac softramp,disable DAC_EQ */
    es8311_write_reg(ES8311_DAC_REG37, 0x08);
    es8311_write_reg(ES8311_DAC_REG32, 0xBF);

    // /* set adc gain scale up */
    // es8311_write_reg(ES8311_ADC_REG16, 0x24);
    // /* set adc alc maxgain */
    // es8311_write_reg(ES8311_ADC_REG17, 0xBF);
    // /* adc alc disable,alc_winsize */
    // es8311_write_reg(ES8311_ADC_REG18, 0x07);
    // /* set alc target level */
    // es8311_write_reg(ES8311_ADC_REG19, 0xFB);
    // /* set adc_automute noise gate */
    // es8311_write_reg(ES8311_ADC_REG1A, 0x03);
    // /* set adc_automute vol */
    // es8311_write_reg(ES8311_ADC_REG1B, 0xEA);
    return 0;
}

static int es8311_codec_init(audio_codec_conf_t* conf){
    uint8_t temp1 = 0, temp2 = 0, temp3 = 0;
    if (conf->pa_pin != -1){
        luat_gpio_mode(conf->pa_pin, Luat_GPIO_OUTPUT, Luat_GPIO_DEFAULT, !conf->pa_on_level);
        luat_gpio_set(conf->pa_pin, !conf->pa_on_level);
    }
    luat_i2c_setup(0, I2C_REQ);
    temp1 = es8311_read_reg(ES8311_CHD1_REGFD);
    temp2 = es8311_read_reg(ES8311_CHD2_REGFE);
    temp3 = es8311_read_reg(ES8311_CHVER_REGFF);
    if(temp1 != 0x83 || temp2 != 0x11){
        LLOGE("codec err, id = 0x%x 0x%x ver = 0x%x", temp1, temp2, temp3);
        return -1;
    }
    es8311_reg_init();
    return 0;
}

static int es8311_codec_deinit(audio_codec_conf_t* conf){

    return 0;
}

static void es8311_codec_pa(audio_codec_conf_t* conf,uint8_t on){
	if (on){
        luat_timer_mdelay(conf->dummy_time_len);
        luat_gpio_set(conf->pa_pin, conf->pa_on_level);
        luat_timer_mdelay(conf->pa_delay_time);
	}else{	
        luat_gpio_set(conf->pa_pin, !conf->pa_on_level);
	}
}

static int es8311_codec_control(audio_codec_conf_t* conf,uint8_t cmd,int data){
    switch (cmd)
    {
    case CODEC_CTL_MODE:
        es8311_codec_mode((uint8_t)data);
        break;
    case CODEC_CTL_VOLUME:
        es8311_codec_vol((uint8_t)data);
        break;
    case CODEC_CTL_RATE:
        es8311_codec_samplerate((uint16_t)data);
        break;
    case CODEC_CTL_BITS:
        es8311_codec_samplebits((uint8_t)data);
        break;
    case CODEC_CTL_CHANNEL:
        es8311_codec_channels((uint8_t)data);
        break;
    case CODEC_CTL_PA:
        es8311_codec_pa(conf,(uint8_t)data);
        break;
    default:
        break;
    }
    return 0;
}

static int es8311_codec_start(audio_codec_conf_t* conf){

    return 0;
}

static int es8311_codec_stop(audio_codec_conf_t* conf){

    return 0;
}

const audio_codec_opts_t codec_opts_es8311 = {
    .name = "es8311",
    .init = es8311_codec_init,
    .deinit = es8311_codec_deinit,
    .control = es8311_codec_control,
    .start = es8311_codec_start,
    .stop = es8311_codec_stop,
};

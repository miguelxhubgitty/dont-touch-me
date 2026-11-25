"""Original procedural swing-whoosh and softened cardboard SFX (v3).
Requires numpy and scipy. Outputs short mono PCM-16 WAVs, 44.1 kHz.
All material synthesized from scratch; no third-party samples.
"""
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt
import soundfile as sf

SR = 44100
ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'generated_v3'
OUT.mkdir(exist_ok=True)

def lowpass(x, cutoff):
    return sosfilt(butter(3, cutoff, 'lowpass', fs=SR, output='sos'), x)

def bandpass(x, lo, hi):
    return sosfilt(butter(2, [lo,hi], 'bandpass', fs=SR, output='sos'), x)

def env_gust(t, center, width, shape=1.4):
    g=np.maximum(0, 1-abs((t-center)/width))
    return np.sin(0.5*np.pi*g)**shape

def noise(n, seed, cutoff=800):
    gen=np.random.default_rng(seed)
    x=gen.standard_normal(n)
    x=lowpass(x,cutoff)
    x=x/(np.std(x)+1e-9)
    return x

def write(path, x, peak=.57):
    x=np.asarray(x,dtype=float)
    x=np.tanh(x*.85)
    edge=min(round(SR*.009),len(x)//3)
    x[:edge]*=np.linspace(0,1,edge)
    x[-edge:]*=np.linspace(1,0,edge)
    x*=peak/(max(np.max(abs(x)),1e-8))
    location=OUT/path
    location.parent.mkdir(parents=True,exist_ok=True)
    sf.write(location,x,SR, subtype='PCM_16')
    return location

def whoosh(raising=True):
    """Swinging wooden sign: rounded movement of air, NOT hiss/static."""
    dur=.40 if raising else .37
    t=np.arange(int(SR*dur))/SR
    n=len(t)
    base=noise(n,2031 if raising else 2032,cutoff=1300)
    body=lowpass(base,640)
    mid=bandpass(base,370,1280)
    low=noise(n,3033 if raising else 3034, cutoff=260)
    p=env_gust(t,.205 if raising else .178,.188 if raising else .175,1.15)
    p2=env_gust(t,.235 if raising else .20,.155,1.35)
    f=(175+65*np.exp(-((t-.16)/.14)**2)) if raising else (220-65*t/dur)
    phase=2*np.pi*np.cumsum(f)/SR
    shade=np.sin(phase)*.10
    y=(.19*body + .065*mid)*p + .065*low*p2 + .06*shade*p
    stop=.032*np.sin(2*np.pi*145*t)*np.exp(-np.maximum(t-(.335 if raising else .305),0)*40)
    stop*=env_gust(t,.346 if raising else .32,.048)
    y+=stop
    return t,y

def stiff_rustle(raising=True):
    """Board/panel bend: rubbing low cardboard fibres, no sharp static crackle."""
    dur=.41 if raising else .43
    t=np.arange(int(SR*dur))/SR
    n=len(t)
    gen=np.random.default_rng(660 if raising else 661)
    raw=gen.standard_normal(n)
    low=lowpass(raw,460)
    mid=bandpass(raw,210,860)
    low/=(np.std(low)+1e-9)
    mid/=(np.std(mid)+1e-9)
    bend=env_gust(t,.188 if raising else .205,.185 if raising else .198,1.1)
    roll=0.63+0.22*np.sin(2*np.pi*(8*t+12*t*t)) + .15*np.sin(2*np.pi*(15*t+18*t*t))
    friction=(.185*low + .055*mid)*bend*roll
    spots=[(.100,118,.13,.064),(.286,100,.17,.064)] if raising else [(.082,116,.12,.062),(.315,88,.22,.075)]
    bumps=np.zeros_like(t)
    for at, freq, amp, length in spots:
        u=np.maximum(t-at,0)
        envelope=np.where((t>=at)&(u<length),np.sin(np.pi*np.clip(u/length,0,1))**1.1,0)
        bumps+=amp*np.sin(2*np.pi*(freq*u-.35*freq*u*u/length))*envelope
    hum=.042*np.sin(2*np.pi*(143*t-25*t*t))*env_gust(t,.25,.17)
    return t,friction+bumps+hum

if __name__=='__main__':
    for path,source,raise_ in [
        ('character/sign_raise_air_swing_v3.wav',whoosh,True),
        ('character/sign_lower_air_swing_v3.wav',whoosh,False),
        ('character/box_raise_soft_cardboard_v3.wav',stiff_rustle,True),
        ('character/box_lower_soft_cardboard_v3.wav',stiff_rustle,False),
    ]:
        t,x=source(raise_)
        p=write(path,x)
        print(p, f'{len(x)/SR:.3f}s')

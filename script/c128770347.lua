local s,id=GetID()
function s.initial_effect(c)
	-----------------------------------------------------
	-- ① 이 카드는 튜너로도 취급
	-----------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EFFECT_ADD_TYPE)
	e0:SetValue(TYPE_TUNER)
	c:RegisterEffect(e0)

	-----------------------------------------------------
	-- ② 패에서 소재로 사용되는 것은 엔진상 불가능하므로 생략
	--	(EDOPro 기본 환경에서는 지원 안됨)
	-----------------------------------------------------

	-----------------------------------------------------
	-- ③ 싱크로/링크 소재로 묘지로 보내졌을 때
	--	→ 요정향 몬스터 추가 일반 소환권 +2
	-----------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.excon)
	e3:SetOperation(s.exop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- 싱크로 / 링크 소재 판정
-------------------------------------------------
function s.excon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_SYNCHRO)~=0 or (r&REASON_LINK)~=0
end

-------------------------------------------------
-- 요정향 몬스터에 한해 추가 일반 소환 2회
-------------------------------------------------
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetTarget(s.sumfilter)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.sumfilter(e,c)
	return c:IsSetCard(0x767)
end

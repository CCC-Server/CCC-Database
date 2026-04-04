--셀레스티얼 타이탄-원 어보브 올
local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 (비튜너가 싱크로 몬스터)
	Synchro.AddProcedure(c,nil,1,1,
		s.synfilter,1,99)
	c:EnableReviveLimit()
	Pendulum.AddProcedure(c)
	-- E1: 퀵 제외
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)
end

s.listed_series={0xc02}
s.listed_names={id}

-- 비튜너 조건: 빛 속성 + 싱크로 몬스터
function s.synfilter(c,scard,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsType(TYPE_SYNCHRO)
end

-- 코스트: LP 1000
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLP(tp,1000)
end

-- 대상: 상대 필드 카드 1장
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsControler(1-tp)
	end
	if chk==0 then 
		return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

-- 제외 실행
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end
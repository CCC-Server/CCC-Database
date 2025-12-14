--스펠크래프트 링크 서포터
local s,id=GetID()
function s.initial_effect(c)
	--① 링크 마커 아래에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--② 대상 몬스터 지정 → 발동/공격 시 가마솥에 카운터 추가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	--③ 링크 소재로 묘지로 보내졌을 경우 토큰 2장 특수 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.tkcon)
	e3:SetTarget(s.tktg)
	e3:SetOperation(s.tkop)
	c:RegisterEffect(e3)
end

s.cauldron=128770286

------------------------------------------
--① 링크 마커 아래에 특수 소환
------------------------------------------
function s.linkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x761) and c:IsType(TYPE_LINK)
end
function s.zonefilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x761) and c:IsType(TYPE_LINK)
		and Duel.GetLinkedZone(tp)~=0
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	--필드의 스펠크래프트 링크 몬스터 존재 + 해당 링크 몬스터 마커 아래 존 존재
	local zone=0
	local g=Duel.GetMatchingGroup(s.linkfilter,tp,LOCATION_MZONE,0,nil)
	for tc in g:Iter() do
		zone=zone|tc:GetLinkedZone(tp)
	end
	return Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone)>0
end

------------------------------------------
--② 대상 몬스터 지정 → 발동/공격 시 가마솥에 마력 카운터 추가
------------------------------------------
function s.ctfilter(c)
	return c:IsFaceup()
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(s.ctfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.ctfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,2,nil)
	e:SetLabelObject(g)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if not g then return end
	local c=e:GetHandler()
	for tc in aux.Next(g) do
		--그 몬스터가 공격 선언하거나 효과 발동할 때 카운터 1개 추가
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_ATTACK_ANNOUNCE)
		e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
			return Duel.GetAttacker()==tc
		end)
		e1:SetOperation(s.addct)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)

		local e2=e1:Clone()
		e2:SetCode(EVENT_CHAINING)
		e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
			return eg:IsContains(tc)
		end)
		Duel.RegisterEffect(e2,tp)
	end
end

function s.addct(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(c) return c:IsFaceup() and c:IsCode(s.cauldron) end,tp,LOCATION_SZONE,0,nil)
	local tc=g:GetFirst()
	if tc then tc:AddCounter(COUNTER_SPELL,1) end
end

------------------------------------------
--③ 링크 소재로 묘지로 보내졌을 때
------------------------------------------
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_LINK)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsPlayerCanSpecialSummonMonster(tp,128770268,0x761,TYPES_TOKEN,100,100,1,RACE_SPELLCASTER,ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=1 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,128770268,0x761,TYPES_TOKEN,100,100,1,RACE_SPELLCASTER,ATTRIBUTE_DARK) then return end
	for i=1,2 do
		local token=Duel.CreateToken(tp,128770268)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
		--릴리스 제한 (스펠크래프트 링크 소환만 가능)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UNRELEASABLE_SUM)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetValue(function(e,c,tp,sumtype) return sumtype~=SUMMON_TYPE_LINK or not c:IsSetCard(0x761) end)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e1,true)
	end
	Duel.SpecialSummonComplete()
end

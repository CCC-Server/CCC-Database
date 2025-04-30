--Blaze Cannon Bringer
local s,id=GetID()
function s.initial_effect(c)
	--① 패/필드에서 자신 묘지로 → 브레이즈 캐논 지속 마/함 덱에서 앞면 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.setcost)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--② 묘지에서 발동: 상대 필드에 토큰 소환 후 자신 부활
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
s.listed_names={69537999,id}
s.listed_series={SET_VOLCANIC}

--① 코스트: 자신을 묘지로
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

--① 타겟 설정: 덱에 브레이즈 캐논 지속 마/함 존재 여부 확인
function s.setfilter(c)
	return c:IsCode(69537999) and c:IsType(TYPE_CONTINUOUS) and c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsForbidden()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
end

--① 처리: 덱에서 브레이즈 캐논 지속 마/함 1장 앞면으로 세트
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end

--② 조건: 자신 필드에 브레이즈 캐논이 앞면 존재할 때
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsCode(69537999) end,tp,LOCATION_ONFIELD,0,1,nil)
end

--② 대상 확인
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0x32,TYPE_TOKEN,1000,1000,1,RACE_PYRO,ATTRIBUTE_FIRE,POS_FACEUP,1-tp)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,1-tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

--② 처리: 폭탄 토큰을 상대 필드에 특수 소환하고, 자신도 특수 소환
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0x32,TYPE_TOKEN,1000,1000,1,RACE_PYRO,ATTRIBUTE_FIRE,POS_FACEUP,1-tp) then
		local token=Duel.CreateToken(tp,id+1)
		Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP)
	end
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

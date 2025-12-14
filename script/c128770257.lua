--Dragon Dual Burial Fusion
local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 조건: 드래곤족 듀얼 몬스터 ×2
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.ffilter,2,2)
	--듀얼 몬스터 취급 (필드/묘지에서 일반 몬스터로)
	Gemini.AddProcedure(c)

	--②: 듀얼 상태일 때 발동 가능 - 드래곤 듀얼 묘지로 보내고 레벨 이하 전멸
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(Gemini.EffectStatusCondition)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	--②-2 융합 소재로 묘지로 갔을 때 1000 데미지
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.damcon)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)
end

--융합 소재: 드래곤족 듀얼 몬스터
function s.ffilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_GEMINI,fc,sumtype,tp)
end

--① 효과: 패/덱에서 드래곤족 듀얼 몬스터 1장 묘지로 보내고, 그 레벨 이하 몬스터 전부 파괴
function s.tgfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI) and c:IsAbleToGrave()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tc=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil):GetFirst()
	if tc and Duel.SendtoGrave(tc,REASON_EFFECT)>0 then
		local lv=tc:GetLevel()
		if lv>0 then
			local g=Duel.GetMatchingGroup(function(c,lv)
				return c:IsFaceup() and (c:GetLevel()>0 and c:GetLevel()<=lv or c:IsRankBelow(lv))
			end,tp,0,LOCATION_MZONE,nil,lv)
			if #g>0 then
				Duel.Destroy(g,REASON_EFFECT)
			end
		end
	end
end

--②-2 융합소재로 묘지로 보냈을 경우
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_FUSION)
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Damage(1-tp,1000,REASON_EFFECT)
end

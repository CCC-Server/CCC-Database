--암군의 융합사 β
local s,id=GetID()
function s.initial_effect(c)
	--① 자신/상대 턴: 융합 몬스터 공개 → 특소 & 이름 복사 & (턴중 Extra 제한)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--② 일소/특소 성공 시 → 패/필드만 소재로 융합 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(function() return not Duel.IsPhase(PHASE_DAMAGE) end)
	e2:SetTarget(Fusion.SummonEffTG())
	e2:SetOperation(Fusion.SummonEffOP())
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end
s.listed_series={0xc45}

-----------------------------------------------------------
-- ① 코스트: 엑덱 융합몬스터 공개 / 특소 / 이름복사 / (턴중 Extra 제한)
-----------------------------------------------------------
function s.costfilter(c)
	return c:IsType(TYPE_FUSION) and c.material and #c.material>0
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local fc=g:GetFirst()
	Duel.ConfirmCards(1-tp,fc)
	e:SetLabelObject(fc)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local fc=e:GetLabelObject()
	if not fc or not c:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- 명시된 소재 중 1장 선택 → 코드 복사 (턴 종료시까지)
	local codes={}
	for _,code in ipairs(fc.material) do table.insert(codes,code) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	local selcode=Duel.AnnounceNumber(tp,table.unpack(codes))
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetValue(selcode)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)

	-- 디메리트: 이 턴, Extra에서 LIGHT/DARK만 특수 소환 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetDescription(aux.Stringid(id,2)) -- 카드 텍스트: "이 턴, 자신은 빛/어둠 속성 몬스터밖에 엑스트라 덱에서 특수 소환할 수 없다."
	e2:SetTargetRange(1,0)
	e2:SetTarget(function(_e,sc)
		return sc:IsLocation(LOCATION_EXTRA)
			and not (sc:IsAttribute(ATTRIBUTE_LIGHT) or sc:IsAttribute(ATTRIBUTE_DARK))
	end)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end
